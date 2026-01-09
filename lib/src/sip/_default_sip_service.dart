part of '../telephone.dart';

class _DefaultSipService implements SipService, SipUaHelperListener {
  String? _userAgent;

  final _sipHelper = SIPUAHelper(
    customLogger: Logger(level: Level.error),
  );

  final _registrationStateController =
      StreamController<RegistrationState>.broadcast();
  final _transportStateController =
      StreamController<TransportState>.broadcast();
  final _callEventController =
      StreamController<TelephoneCallUpdated>.broadcast();

  final _callsByRaw = <Call, TelephoneCall>{};
  Completer<OutboundCall>? _pendingOutboundCall;
  Call? _activeOutboundCall;

  _DefaultSipService({String? userAgent}) : _userAgent = userAgent {
    _sipHelper.addSipUaHelperListener(this);
  }

  @override
  bool get connected => _sipHelper.connected;

  @override
  bool get connecting => _sipHelper.connecting;

  @override
  bool get registered => _sipHelper.registered;

  @override
  Stream<RegistrationState> get registrationStates =>
      _registrationStateController.stream;

  @override
  Stream<TransportState> get transportStates =>
      _transportStateController.stream;

  @override
  Stream<TelephoneCallUpdated> get callEvents => _callEventController.stream;

  @override
  Future<void> connect({
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

    return _sipHelper.start(settings);
  }

  @override
  void disconnect() {
    _failPendingOutboundCall(StateError('SipService disconnected'));
    _terminateActiveCalls();
    _activeOutboundCall = null;
    _sipHelper.stop();
  }

  @override
  Future<OutboundCall> dial(String target) async {
    if (!canStartOutboundDial()) {
      throw StateError('Outbound call already in progress');
    }

    final completer = Completer<OutboundCall>();
    _pendingOutboundCall = completer;

    try {
      await _startOutboundCall(target);
      return completer.future;
    } catch (error) {
      _clearPendingOutboundCall(completer);
      rethrow;
    }
  }

  bool canStartOutboundDial() =>
      _pendingOutboundCall == null && _activeOutboundCall == null;

  Future<void> _startOutboundCall(String target) async {
    final mediaStream = await _getAudioStream();
    final started = await _sipHelper.call(
      target,
      voiceOnly: true,
      mediaStream: mediaStream,
    );

    if (!started) {
      throw StateError('Failed to initiate call to $target');
    }
  }

  Future<void> _answerCall(Call call) async {
    final mediaStream = await _getAudioStream();
    call.answer(
      _sipHelper.buildCallOptions(true),
      mediaStream: mediaStream,
    );
  }

  void dispose() {
    _sipHelper.removeSipUaHelperListener(this);
    _failPendingOutboundCall(StateError('SipService disposed'));
    for (final call in _callsByRaw.values) {
      call._dispose();
    }
    _callsByRaw.clear();
    _activeOutboundCall = null;
    _registrationStateController.close();
    _transportStateController.close();
    _callEventController.close();
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    _registrationStateController.add(state);
  }

  @override
  void transportStateChanged(TransportState state) {
    _transportStateController.add(state);
  }

  @override
  void callStateChanged(Call call, CallState state) async {
    final wrappedCall = _wrapCall(call);
    await wrappedCall._applyStateChange(state);
    _callEventController.add(TelephoneCallUpdated(wrappedCall, state.state));

    _completeOutboundDialIfPending(call, wrappedCall);

    if (state.state == CallStateEnum.ENDED ||
        state.state == CallStateEnum.FAILED) {
      _callsByRaw.remove(call);
      if (identical(_activeOutboundCall, call)) {
        _activeOutboundCall = null;
      }
      wrappedCall._dispose();
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  TelephoneCall _wrapCall(Call call) => _callsByRaw.putIfAbsent(
      call,
      () => CallDirection.isInbound(call)
          ? InboundCall._(this, call)
          : OutboundCall._(this, call));

  void _completeOutboundDialIfPending(Call call, TelephoneCall wrappedCall) {
    if (wrappedCall is! OutboundCall) return;
    if (identical(_activeOutboundCall, call)) return;
    final pending = _pendingOutboundCall;
    if (pending == null) return;

    _pendingOutboundCall = null;
    _activeOutboundCall = call;
    if (!pending.isCompleted) {
      pending.complete(wrappedCall);
    }
  }

  void _terminateActiveCalls() {
    final activeCalls = _callsByRaw.values.toList();
    for (final call in activeCalls) {
      unawaited(call.hangup());
      call._dispose();
    }
    _callsByRaw.clear();
  }

  void _failPendingOutboundCall(Object error) {
    final pending = _pendingOutboundCall;
    if (pending == null) {
      return;
    }
    _pendingOutboundCall = null;
    if (!pending.isCompleted) {
      pending.completeError(error);
    }
  }

  void _clearPendingOutboundCall(Completer<OutboundCall> completer) {
    if (identical(_pendingOutboundCall, completer)) {
      _pendingOutboundCall = null;
    }
  }

  Future<MediaStream> _getAudioStream() async {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await Permission.microphone.request();
    }

    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };

    return navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  Future<String> _getUserAgent() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.appName} ${packageInfo.version}';
  }
}
