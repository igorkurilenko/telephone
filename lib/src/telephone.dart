import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:toastification/toastification.dart';

import 'widgets/call_dialog.dart';
import 'widgets/incoming_call_widget.dart';

part 'call/call_manager.dart';
part 'call/call_session.dart';
part 'sip/model/call_direction.dart';
part 'sip/model/sip_account.dart';
part 'sip/model/sip_endpoint.dart';
part 'sip/sip_service.dart';
part 'sip/sip_service_listener.dart';
part 'sip/_sip_agent.dart';

typedef FutureCallback<T> = Future<T> Function();

typedef TelephoneLayoutBuilder = Widget Function(
    BuildContext context, Widget child);

typedef TelephoneCallWidgetBuilder = Widget Function(
    BuildContext context, SipService sipService, Call call);

typedef IncomingCallCallback = void Function(SipService sipService, Call call);

class Telephone extends StatefulWidget {
  final Widget child;
  final TelephoneLayoutBuilder layoutBuilder;
  final TelephoneCallWidgetBuilder incomingCallWidgetBuilder;
  final TelephoneCallWidgetBuilder callDialogBuilder;
  final String? userAgent;

  /// Optional CallManager configuration
  /// If provided, enables enhanced call management features
  final CallManagerConfig? callManagerConfig;

  /// Callbacks for CallManager (only used if callManagerConfig is provided)
  final OnIncomingCallCallback? onIncomingCall;
  final OnCallAcceptedCallback? onCallAccepted;
  final OnCallEndedCallback? onCallEnded;

  const Telephone({
    super.key,
    required this.child,
    this.layoutBuilder = Telephone.defaultLayoutBuilder,
    this.incomingCallWidgetBuilder = Telephone.defaultIncomingCallWidgetBuilder,
    this.callDialogBuilder = Telephone.defaultCallDialogBuilder,
    this.userAgent,
    this.callManagerConfig,
    this.onIncomingCall,
    this.onCallAccepted,
    this.onCallEnded,
  });

  @override
  State<Telephone> createState() => TelephoneState();

  static Widget defaultLayoutBuilder(
    BuildContext context,
    Widget child,
  ) =>
      ToastificationWrapper(
        child: Material(
          child: child,
        ),
      );

  static Widget defaultIncomingCallWidgetBuilder(
    BuildContext context,
    SipService sipService,
    Call call,
  ) =>
      IncomingCallWidget(
        sipService: sipService,
        call: call,
      );

  static Widget defaultCallDialogBuilder(
    BuildContext context,
    SipService sipService,
    Call call,
  ) =>
      CallDialog(
        sipService: sipService,
        call: call,
      );

  static TelephoneState of(BuildContext context) {
    final TelephoneState? result = Telephone.maybeOf(context);
    assert(() {
      if (result == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'Telephone.of() called with a context that does not contain an Telephone.'),
          ErrorDescription(
            'No Telephone ancestor could be found starting from the context that was passed to Telephone.of().',
          ),
          context.describeElement('The context used was'),
        ]);
      }
      return true;
    }());
    return result!;
  }

  static TelephoneState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<TelephoneState>();
}

class TelephoneState extends State<Telephone>
    implements SipService, SipServiceListener {
  late final _sipAgent = _SipAgent(
    userAgent: widget.userAgent,
  );
  final _toastsByCall = <Call, ToastificationItem>{};
  Call? _activeCall;

  /// CallManager instance (if enabled via callManagerConfig)
  CallManager? _callManager;

  /// Access to CallManager for enhanced features
  CallManager? get callManager => _callManager;

  Call? get acceptedCall => _activeCall;

  Iterable<Call> get incomingCalls => _toastsByCall.keys;

  bool get connected => _sipAgent.connected;

  bool get connecting => _sipAgent.connecting;

  bool get registered => _sipAgent.registered;

  @override
  void initState() {
    super.initState();

    assert(Telephone.maybeOf(context) == null,
        'Only one instance of the Telephone widget is allowed in the widget tree.');

    _sipAgent.addSipServiceListener(this);

    // Initialize CallManager if config provided
    if (widget.callManagerConfig != null) {
      _callManager = CallManager(
        sipService: this,
        config: widget.callManagerConfig!,
        onIncomingCall: widget.onIncomingCall,
        onCallAccepted: widget.onCallAccepted,
        onCallEnded: widget.onCallEnded,
      );
    }
  }

  @override
  void dispose() {
    _callManager?.dispose();
    _sipAgent.removeSipServiceListener(this);
    _sipAgent.disconnect();
    super.dispose();
  }

  @override
  Future<void> connect(
          {required SipEndpoint endpoint, required SipAccount account}) =>
      _sipAgent.connect(endpoint: endpoint, account: account);

  @override
  Future<bool> call(String target) => _sipAgent.call(target);

  @override
  Future<void> answer(Call call) => _sipAgent.answer(call);

  @override
  void hangup(Call call) => _sipAgent.hangup(call);

  @override
  void addSipServiceListener(SipServiceListener listener) =>
      _sipAgent.addSipServiceListener(listener);

  @override
  void removeSipServiceListener(SipServiceListener listener) =>
      _sipAgent.removeSipServiceListener(listener);

  @override
  Widget build(BuildContext context) {
    return widget.layoutBuilder(context, widget.child);
  }

  @override
  void disconnect() => _sipAgent.disconnect();

  @override
  void registrationStateChanged(RegistrationState state) {}

  @override
  void callStateChanged(Call call, CallState callState) {
    switch (callState.state) {
      case CallStateEnum.CALL_INITIATION:
        _handleCallInitiation(call);
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        _handleCallAccepted(call);
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        _handleCallEnded(call);
        break;
      default:
        break;
    }
  }

  Widget _buildIncomingCall(Call call) =>
      widget.incomingCallWidgetBuilder(context, this, call);

  void _handleCallInitiation(Call call) => CallDirection.isIncoming(call)
      ? _handleIncomingCallInitiation(call)
      : _handleOutgoingCallInitiation(call);

  void _handleIncomingCallInitiation(Call call) {
    if (kIsWeb) {
      _showIncomingCallToast(call);
    }
  }

  void _handleOutgoingCallInitiation(Call call) {
    assert(_activeCall == null, 'Multiple outgoing calls initiated');

    _activeCall = call;
    _showActiveCallDialog(call);
  }

  void _handleCallAccepted(Call call) {
    _dismissIncomingCallToast(call);

    _activeCall = call;
    _showActiveCallDialog(call);
  }

  void _handleCallEnded(Call call) {
    _dismissIncomingCallToast(call);

    if (_activeCall == call) {
      _activeCall = null;
    }
  }

  void _showActiveCallDialog(Call call) {
    final callWidget = widget.callDialogBuilder(context, _sipAgent, call);

    // Don't show dialog if builder returns SizedBox.shrink()
    if (callWidget.runtimeType.toString() == 'SizedBox') {
      final sizedBox = callWidget as SizedBox;
      if (sizedBox.width == 0.0 && sizedBox.height == 0.0) {
        return;
      }
    }

    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secAnimation) => callWidget,
    );
  }

  void _showIncomingCallToast(Call call) {
    final toastItem = toastification.showCustom(
      context: context,
      alignment: Alignment.topCenter,
      builder: (BuildContext context, ToastificationItem holder) => Dismissible(
        key: ValueKey(call.id ?? call.hashCode),
        direction: DismissDirection.up,
        behavior: HitTestBehavior.deferToChild,
        onDismissed: (_) => _dismissIncomingCallToast(
          call,
          showRemoveAnimation: false,
        ),
        child: _buildIncomingCall(call),
      ),
    );

    _toastsByCall[call] = toastItem;
  }

  void _dismissIncomingCallToast(
    Call call, {
    bool showRemoveAnimation = true,
  }) {
    final toastItem = _toastsByCall.remove(call);
    if (toastItem != null) {
      toastification.dismiss(
        toastItem,
        showRemoveAnimation: showRemoveAnimation,
      );
    }
  }
}
