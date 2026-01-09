part of '../telephone.dart';

class TelephoneCallUpdated {
  TelephoneCallUpdated(this.call, this.state);

  final TelephoneCall call;

  final CallStateEnum state;

  bool get isInbound => call is InboundCall;

  bool get isOutbound => call is OutboundCall;
}
