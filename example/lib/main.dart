import 'dart:async';

import 'package:example/config.dart';
import 'package:flutter/material.dart';
import 'package:telephone/telephone.dart';
import 'package:toastification/toastification.dart';

import 'widgets/call_dialog.dart';
import 'widgets/inbound_call_widget.dart';
import 'widgets/telephone_status_widget.dart';

void main() {
  runApp(
    const ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Telephone(
          child: TelephoneExample(),
        ),
      ),
    ),
  );
}

class TelephoneExample extends StatefulWidget {
  const TelephoneExample({super.key});

  @override
  State<TelephoneExample> createState() => _TelephoneExampleState();
}

class _TelephoneExampleState extends State<TelephoneExample> {
  TelephoneState get telephone => Telephone.of(context);
  StreamSubscription<InboundCall>? _ringingSubscription;
  final _toastsByCall = <InboundCall, ToastificationItem>{};
  TelephoneCall? _activeCall;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();

    unawaited(telephone.connect(
      endpoint: kSipEndpoint,
      account: kSipAccount,
    ));

    _ringingSubscription = telephone.onRinging(_handleInboundCall);
  }

  @override
  void dispose() {
    _ringingSubscription?.cancel();
    telephone.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Align(
            alignment: Alignment.centerLeft,
            child: TelephoneStatusWidget(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildDialButton(),
            )
          ],
        ),
        body: const SizedBox.shrink(),
      );

  Widget _buildDialButton() => StreamBuilder<RegistrationState>(
        stream: telephone.registrationStates,
        builder: (context, snapshot) {
          final canCall = telephone.registered;
          return IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: canCall ? _startOutboundCall : null,
          );
        },
      );

  Future<void> _startOutboundCall() async {
    _replaceActiveCall(null);
    final call = await telephone.dial('400');
    _attachLifecycle(call);
    _showCallDialog(call);
  }

  void _handleInboundCall(InboundCall call) {
    if (_toastsByCall.containsKey(call)) {
      return;
    }

    _showInboundCallToast(
      call,
      onAccept: () {
        _dismissInboundCallToast(call);
        _replaceActiveCall(call);
        unawaited(call.answer());
        _showCallDialog(call);
      },
      onReject: () {
        _dismissInboundCallToast(call);
        unawaited(call.hangup());
      },
    );
    _attachLifecycle(call);
  }

  void _handleCallEnded(TelephoneCall call) {
    if (call is InboundCall) {
      _dismissInboundCallToast(call);
    }
    if (!identical(_activeCall, call)) {
      return;
    }
    _activeCall = null;
    if (_dialogVisible) {
      _closeActiveDialog();
    }
  }

  void _attachLifecycle(TelephoneCall call) {
    call.onEnded((_) => _handleCallEnded(call));
    call.onFailed((_) => _handleCallEnded(call));
  }

  void _replaceActiveCall(TelephoneCall? nextCall) {
    final current = _activeCall;
    if (current == null || identical(current, nextCall)) {
      _activeCall = nextCall;
      return;
    }
    unawaited(current.hangup());
    _closeActiveDialog();
    _activeCall = nextCall;
  }

  void _showCallDialog(TelephoneCall call) {
    if (call.isEnded || call.isFailed) {
      return;
    }
    _activeCall = call;
    _dialogVisible = true;
    showGeneralDialog(
      context: context,
      useRootNavigator: true,
      pageBuilder: (context, animation, secAnimation) => CallDialog(call: call),
    ).whenComplete(() {
      if (!mounted) {
        return;
      }
      _dialogVisible = false;
    });
  }

  void _closeActiveDialog() {
    if (!_dialogVisible) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
    _dialogVisible = false;
  }

  void _showInboundCallToast(
    InboundCall call, {
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    final toastItem = toastification.showCustom(
      context: context,
      alignment: Alignment.topCenter,
      builder: (BuildContext context, ToastificationItem holder) => Dismissible(
        key: ValueKey(call.id ?? call.hashCode),
        direction: DismissDirection.up,
        behavior: HitTestBehavior.deferToChild,
        onDismissed: (_) => _dismissInboundCallToast(
          call,
          showRemoveAnimation: false,
        ),
        child: InboundCallWidget(
          call: call,
          onAccept: onAccept,
          onReject: onReject,
        ),
      ),
    );

    _toastsByCall[call] = toastItem;
  }

  void _dismissInboundCallToast(
    InboundCall call, {
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
