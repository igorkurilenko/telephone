part of '../telephone.dart';

abstract class SipService {
  bool get connected;
  bool get connecting;
  bool get registered;

  Future<void> connect({
    required SipEndpoint endpoint,
    required SipAccount account,
  });

  void disconnect();

  Future<OutboundCall> dial(String target);

  Stream<RegistrationState> get registrationStates;

  Stream<TransportState> get transportStates;

  Stream<TelephoneCallUpdated> get callEvents;
}

extension SipServiceEventHooks on SipService {
  StreamSubscription<RegistrationState> onRegistrationStateChanged(
    void Function(RegistrationState state) cb,
  ) =>
      registrationStates.listen(cb);

  StreamSubscription<RegistrationState> onRegistered(
    void Function(RegistrationState state) cb,
  ) =>
      registrationStates
          .where((state) => state.state == RegistrationStateEnum.REGISTERED)
          .listen(cb);

  StreamSubscription<RegistrationState> onRegistrationFailed(
    void Function(RegistrationState state) cb,
  ) =>
      registrationStates
          .where(
            (state) => state.state == RegistrationStateEnum.REGISTRATION_FAILED,
          )
          .listen(cb);

  StreamSubscription<RegistrationState> onUnregistered(
    void Function(RegistrationState state) cb,
  ) =>
      registrationStates
          .where((state) => state.state == RegistrationStateEnum.UNREGISTERED)
          .listen(cb);

  StreamSubscription<TransportState> onTransportStateChanged(
    void Function(TransportState state) cb,
  ) =>
      transportStates.listen(cb);

  StreamSubscription<TransportState> onTransportConnecting(
    void Function(TransportState state) cb,
  ) =>
      transportStates
          .where((state) => state.state == TransportStateEnum.CONNECTING)
          .listen(cb);

  StreamSubscription<TransportState> onTransportConnected(
    void Function(TransportState state) cb,
  ) =>
      transportStates
          .where((state) => state.state == TransportStateEnum.CONNECTED)
          .listen(cb);

  StreamSubscription<TransportState> onTransportDisconnected(
    void Function(TransportState state) cb,
  ) =>
      transportStates
          .where((state) => state.state == TransportStateEnum.DISCONNECTED)
          .listen(cb);

  StreamSubscription<TelephoneCallUpdated> onCallStateChanged(
    void Function(TelephoneCall call) cb,
  ) =>
      callEvents.listen((event) => cb(event.call));

  StreamSubscription<InboundCall> onInboundCallInitiated(
    void Function(InboundCall call) cb,
  ) =>
      _onInboundCallStates(
        {CallStateEnum.CALL_INITIATION},
        cb,
      );

  StreamSubscription<OutboundCall> onOutboundCallInitiated(
    void Function(OutboundCall call) cb,
  ) =>
      _onOutboundCallStates(
        {CallStateEnum.CALL_INITIATION},
        cb,
      );

  StreamSubscription<InboundCall> onInboundCallAccepted(
    void Function(InboundCall call) cb,
  ) =>
      _onInboundCallStates(
        {CallStateEnum.ACCEPTED},
        cb,
      );

  StreamSubscription<OutboundCall> onOutboundCallAccepted(
    void Function(OutboundCall call) cb,
  ) =>
      _onOutboundCallStates(
        {CallStateEnum.ACCEPTED},
        cb,
      );

  StreamSubscription<InboundCall> onInboundCallConfirmed(
    void Function(InboundCall call) cb,
  ) =>
      _onInboundCallStates(
        {CallStateEnum.CONFIRMED},
        cb,
      );

  StreamSubscription<OutboundCall> onOutboundCallConfirmed(
    void Function(OutboundCall call) cb,
  ) =>
      _onOutboundCallStates(
        {CallStateEnum.CONFIRMED},
        cb,
      );

  StreamSubscription<TelephoneCallUpdated> onCallEnded(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.ENDED}, cb);

  StreamSubscription<TelephoneCallUpdated> onCallFailed(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.FAILED}, cb);

  StreamSubscription<TelephoneCallUpdated> onCallStream(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.STREAM}, cb);

  StreamSubscription<TelephoneCallUpdated> onCallUnmuted(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.UNMUTED}, cb);

  StreamSubscription<TelephoneCallUpdated> onCallMuted(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.MUTED}, cb);

  StreamSubscription<TelephoneCallUpdated> onCallConnecting(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.CONNECTING}, cb);

  StreamSubscription<TelephoneCallUpdated> onCallProgress(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.PROGRESS}, cb);

  StreamSubscription<TelephoneCallUpdated> onCallAccepted(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.ACCEPTED}, cb);

  StreamSubscription<TelephoneCallUpdated> onCallConfirmed(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.CONFIRMED}, cb);

  StreamSubscription<TelephoneCallUpdated> onCallRefer(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.REFER}, cb);

  StreamSubscription<TelephoneCallUpdated> onCallHold(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.HOLD}, cb);

  StreamSubscription<TelephoneCallUpdated> onCallUnhold(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.UNHOLD}, cb);

  StreamSubscription<TelephoneCallUpdated> onCallInitiated(
    void Function(TelephoneCall call) cb,
  ) =>
      _onCallStates({CallStateEnum.CALL_INITIATION}, cb);

  StreamSubscription<TelephoneCallUpdated> _onCallStates(
    Set<CallStateEnum> states,
    void Function(TelephoneCall call) cb,
  ) =>
      _callEventsForStates(states).listen((event) => cb(event.call));

  StreamSubscription<InboundCall> _onInboundCallStates(
    Set<CallStateEnum> states,
    void Function(InboundCall call) cb,
  ) =>
      _callEventsForStates(states)
          .where((event) => event.call is InboundCall)
          .map((event) => event.call as InboundCall)
          .listen(cb);

  StreamSubscription<OutboundCall> _onOutboundCallStates(
    Set<CallStateEnum> states,
    void Function(OutboundCall call) cb,
  ) =>
      _callEventsForStates(states)
          .where((event) => event.call is OutboundCall)
          .map((event) => event.call as OutboundCall)
          .listen(cb);

  Stream<TelephoneCallUpdated> _callEventsForStates(
          Set<CallStateEnum> states) =>
      callEvents.where((event) => states.contains(event.state));
}
