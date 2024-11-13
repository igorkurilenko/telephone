part of '../../telephone.dart';

class CallDirection {
  static const outgoing = 'outgoing';
  static const incoming = 'incoming';

  static bool isOutgoing(Call call) => !isIncoming(call);

  static bool isIncoming(Call call) =>
      call.direction.toLowerCase() == incoming.toLowerCase();
}
