part of '../../telephone.dart';

class CallDirection {
  static bool isOutgoing(Call call) => call.direction == Direction.outgoing;

  static bool isIncoming(Call call) => call.direction == Direction.incoming;
}
