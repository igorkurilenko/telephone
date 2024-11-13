part of '../../telephone.dart';

class SipEndpoint {
  final String host; // SIP server host
  final int port; // Port for TCP transport
  final String wsProtocol; // Protocol for WebSocket (ws or wss)
  final int wsPort; // Port for WebSocket transport
  final String wsPath; // WebSocket path
  final bool webSocketTransport;

  const SipEndpoint({
    required this.host,
    this.port = 5060,
    this.wsProtocol = 'wss',
    this.wsPort = 8089,
    this.wsPath = '/ws',
    this.webSocketTransport = true,
  });

  String get tcpUrl => '$host:$port';
  String get wsUrl => '$wsProtocol://$host:$wsPort$wsPath';
}
