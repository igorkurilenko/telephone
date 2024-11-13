part of '../telephone.dart';

abstract class SipServiceListener {
  void registrationStateChanged(RegistrationState state);

  void callStateChanged(Call call, CallState state);
}

class SipUaHelperListenerAdapter implements SipUaHelperListener {
  final SipServiceListener listener;

  SipUaHelperListenerAdapter.fromSipServiceListener(this.listener);

  @override
  void registrationStateChanged(RegistrationState state) {
    listener.registrationStateChanged(state);
  }

  @override
  void callStateChanged(Call call, CallState state) =>
      listener.callStateChanged(call, state);

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  @override
  int get hashCode => listener.hashCode;

  @override
  bool operator ==(Object other) {
    return other is SipUaHelperListenerAdapter
        ? other.listener == listener
        : other == listener;
  }
}
