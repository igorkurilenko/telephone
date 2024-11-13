import 'package:telephone/telephone.dart';

/// The config that works with the asterisk docker at
/// https://github.com/flutter-webrtc/dockers.git

const kSipEndpoint = SipEndpoint(
  host: '127.0.0.1',
  port: 5060,
  wsProtocol: 'ws',
  wsPort: 8088,
);

const kSipAccount = SipAccount(
  username: '500',
  password: '500',
  displayName: 'Bob',
);
