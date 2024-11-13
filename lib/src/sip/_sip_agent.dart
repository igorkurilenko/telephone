part of '../telephone.dart';

// TODO: ensure connected when call()
// TODO: reconnection strategy
// TODO: reconnection after background=>foreground
// TODO: push notifications for incoming calls
// TODO: web/ios/android correctly display notifications

class _SipAgent implements SipService {

  _SipAgent({String? userAgent}) : _userAgent = userAgent;

  String? _userAgent;

  final _sipAgentHelper = SIPUAHelper(
    customLogger: Logger(level: Level.error),
  );

  bool get connected => _sipAgentHelper.connected;

  bool get connecting => _sipAgentHelper.connecting;

  bool get registered => _sipAgentHelper.registered;

  @override
  void connect({
    required SipEndpoint endpoint,
    required SipAccount account,
  }) async {
    final settings = UaSettings();
    _userAgent = _userAgent ?? await _getUserAgent();

    settings.transportType =
        endpoint.webSocketTransport ? TransportType.WS : TransportType.TCP;

    settings.userAgent = _userAgent;
    settings.host = endpoint.host;
    settings.port = '${endpoint.port}';
    settings.tcpSocketSettings.allowBadCertificate = true;

    settings.webSocketSettings.userAgent = _userAgent;
    settings.webSocketUrl = endpoint.wsUrl;
    settings.webSocketSettings.allowBadCertificate = true;

    settings.contact_uri = 'sip:${account.username}@${endpoint.host}';
    settings.uri = '${account.username}@${endpoint.host}';

    settings.authorizationUser = account.username;
    settings.password = account.password;
    settings.displayName = account.displayName;

    settings.dtmfMode = DtmfMode.RFC2833;

    _sipAgentHelper.start(settings);
  }

  @override
  void disconnect() {
    _sipAgentHelper.stop();
  }

  @override
  Future<bool> call(String target) async {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await Permission.microphone.request();
    }

    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };

    final mediaStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);

    return _sipAgentHelper.call(
      target,
      voiceOnly: true,
      mediaStream: mediaStream,
    );
  }

  @override
  void answer(Call call) async {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await Permission.microphone.request();
    }

    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };

    final mediaStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);

    call.answer(
      _sipAgentHelper.buildCallOptions(true),
      mediaStream: mediaStream,
    );
  }

  @override
  void hangup(Call call) {
    // TODO: stop local/remote stream tracks of call.peerConnection
    // when the bug of the flutter_webrtc will be fixed
    call.session.terminate({'status_code': 603});
  }

  @override
  void addSipServiceListener(SipServiceListener listener) =>
      _sipAgentHelper.addSipUaHelperListener(
        SipUaHelperListenerAdapter.fromSipServiceListener(listener),
      );

  @override
  void removeSipServiceListener(SipServiceListener listener) =>
      _sipAgentHelper.removeSipUaHelperListener(
        SipUaHelperListenerAdapter.fromSipServiceListener(listener),
      );

  Future<String> _getUserAgent() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.appName} ${packageInfo.version}';
  }
}