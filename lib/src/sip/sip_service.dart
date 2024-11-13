part of '../telephone.dart';

abstract class SipService implements HasSipServiceListeners{
  void connect({
    required SipEndpoint endpoint,
    required SipAccount account,
  });

  Future<bool> call(String target);

  void answer(Call call);

  void hangup(Call call);

  void disconnect();
}

abstract class HasSipServiceListeners {
  void addSipServiceListener(SipServiceListener listener);

  void removeSipServiceListener(SipServiceListener listener);
}
