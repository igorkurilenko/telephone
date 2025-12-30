part of '../../telephone.dart';

class CallDirection {
  static bool isOutgoing(Call call) => !isIncoming(call);

  static bool isIncoming(Call call) =>
      call.direction == Direction.incoming;
}
