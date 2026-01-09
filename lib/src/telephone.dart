import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua_webrtc_fixed/sip_ua_webrtc_fixed.dart';

part 'sip/model/call_direction.dart';
part 'sip/model/sip_account.dart';
part 'sip/model/sip_endpoint.dart';
part 'sip/model/telephone_call.dart';
part 'sip/model/telephone_call_media.dart';
part 'sip/sip_service.dart';
part 'sip/sip_service_events.dart';
part 'sip/_default_sip_service.dart';

class Telephone extends StatefulWidget {
  static TelephoneState? _instance;
  final Widget child;
  final String? userAgent;

  const Telephone({
    super.key,
    required this.child,
    this.userAgent,
  });

  @override
  State<Telephone> createState() => TelephoneState();

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
      context.findAncestorStateOfType<TelephoneState>() ?? _instance;
}

class TelephoneState extends State<Telephone> {
  late final _sipService = _DefaultSipService(
    userAgent: widget.userAgent,
  );

  bool get connected => _sipService.connected;

  bool get connecting => _sipService.connecting;

  bool get registered => _sipService.registered;

  Stream<RegistrationState> get registrationStates =>
      _sipService.registrationStates;

  Stream<TransportState> get transportStates => _sipService.transportStates;

  Stream<TelephoneCallUpdated> get callEvents => _sipService.callEvents;

  @override
  void initState() {
    super.initState();

    assert(Telephone.maybeOf(context) == null,
        'Only one instance of the Telephone widget is allowed in the widget tree.');
    Telephone._instance = this;
  }

  @override
  void dispose() {
    _sipService.disconnect();
    _sipService.dispose();
    if (identical(Telephone._instance, this)) {
      Telephone._instance = null;
    }
    super.dispose();
  }

  Future<void> connect({
    required SipEndpoint endpoint,
    required SipAccount account,
  }) =>
      _sipService.connect(endpoint: endpoint, account: account);

  StreamSubscription<InboundCall> onRinging(
    void Function(InboundCall call) cb,
  ) =>
      _sipService.onInboundCallInitiated(cb);

  Future<OutboundCall> dial(String target) => _sipService.dial(target);

  void disconnect() => _sipService.disconnect();

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
