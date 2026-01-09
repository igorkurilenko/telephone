part of '../../telephone.dart';

class CallDirection {
  static bool isOutbound(Call call) => call.direction == Direction.outgoing;

  static bool isInbound(Call call) => call.direction == Direction.incoming;
}
