part of '../../telephone.dart';

// TODO: refactor 
// TODO: correcly handle media stream fails
abstract class TelephoneCall {
  TelephoneCall._(this._service, this._call) : _state = _call.state;

  final _DefaultSipService _service;
  final Call _call;
  final _eventController = StreamController<TelephoneCall>.broadcast();
  TelephoneCallMedia? _media;
  Future<TelephoneCallMedia>? _mediaFuture;
  CallStateEnum _state;
  bool? _originatorIsLocal;
  bool? _originatorIsRemote;
  bool _localHangupRequested = false;
  int? _errorCode;
  String? _errorReason;
  String? _errorPhrase;
  bool? _audio;
  bool? _video;
  MediaStream? _localOriginatorStream;
  MediaStream? _remoteOriginatorStream;

  String? get id => _call.id;

  String? get remoteIdentity => _call.remote_identity;

  String? get remoteDisplayName => _call.remote_display_name;

  String? get localIdentity => _call.local_identity;

  CallStateEnum get state => _state;

  bool get isLocalOriginator => _originatorIsLocal ?? false;

  bool get isRemoteOriginator => _originatorIsRemote ?? false;

  int? get errorCode => _errorCode;

  String? get errorReason => _errorReason;

  String? get errorPhrase => _errorPhrase;

  bool? get audio => _audio;

  bool? get video => _video;

  MediaStream? get localOriginatorStream => _localOriginatorStream;

  MediaStream? get remoteOriginatorStream => _remoteOriginatorStream;

  bool get hasLocalOriginatorStream => _localOriginatorStream != null;

  bool get hasRemoteOriginatorStream => _remoteOriginatorStream != null;

  Stream<TelephoneCall> get events => _eventController.stream;

  bool get isEnded => _state == CallStateEnum.ENDED;

  bool get isFailed => _state == CallStateEnum.FAILED;

  Future<void> hangup() async {
    _localHangupRequested = true;
    try {
      await _stopStreamTracks();
    } finally {
      _call.session.terminate({'status_code': 603});
    }
  }

  void hold() => _call.hold();

  void unhold() => _call.unhold();

  void mute({bool audio = true, bool video = true}) => _call.mute(audio, video);

  void unmute({bool audio = true, bool video = true}) =>
      _call.unmute(audio, video);

  void sendDtmf(String tones) => _call.sendDTMF(tones);

  Future<TelephoneCallMedia> ensureMedia({
    bool enableSpeakerphone = false,
  }) {
    final existingMedia = _media;
    if (existingMedia != null) {
      existingMedia.setSpeakerphone(enableSpeakerphone);
      return Future.value(existingMedia);
    }
    if (_mediaFuture != null) {
      return _mediaFuture!;
    }

    final completer = Completer<TelephoneCallMedia>();
    _mediaFuture = completer.future;

    () async {
      try {
        final media = TelephoneCallMedia._(
          this,
          enableSpeakerphone: enableSpeakerphone,
        );
        await media.initialize();
        _media = media;
        _syncMediaRenderers();
        completer.complete(media);
      } catch (error, stackTrace) {
        _mediaFuture = null;
        _media = null;
        completer.completeError(error, stackTrace);
      }
    }();

    return _mediaFuture!;
  }

  TelephoneCallMedia? get media => _media;

  Future<void> _applyStateChange(CallState state) async {
    _state = state.state;
    _updateOriginator(state.originator);
    _updateFailure(state.cause);
    _updateMediaFlags(state.audio, state.video);
    _updateStreams(state.originator, state.stream);
    try {
      await ensureMedia();
    } catch (_) {
      // Keep state updates flowing even if media init fails.
    }
    _syncMediaRenderers();
    _emitStateChange();
  }

  void _updateOriginator(Originator? originator) {
    if (originator == null) {
      return;
    }
    _originatorIsLocal = originator == Originator.local;
    _originatorIsRemote = originator == Originator.remote;
  }

  void _updateFailure(dynamic cause) {
    if (cause == null) {
      return;
    }
    _errorCode = cause.status_code ?? _errorCode;
    _errorReason = cause.cause ?? _errorReason;
    _errorPhrase = cause.reason_phrase ?? _errorPhrase;
  }

  void _updateMediaFlags(bool? audio, bool? video) {
    _audio = audio ?? _audio;
    _video = video ?? _video;
  }

  void _updateStreams(Originator? originator, MediaStream? stream) {
    if (stream == null) {
      return;
    }
    if (originator == Originator.local) {
      _localOriginatorStream = stream;
    } else if (originator == Originator.remote) {
      _remoteOriginatorStream = stream;
    } else {
      final hadLocalStream = _localOriginatorStream != null;
      _localOriginatorStream ??= stream;
      if (hadLocalStream) {
        _remoteOriginatorStream ??= stream;
      }
    }
  }

  void _syncMediaRenderers() {
    final media = _media;
    if (media == null) {
      return;
    }
    _applyRenderer(media.localRenderer, _localOriginatorStream);
    _applyRenderer(media.remoteRenderer, _remoteOriginatorStream);
    if (_localOriginatorStream != null) {
      media._applySpeakerphone();
    }
  }

  void _applyRenderer(RTCVideoRenderer renderer, MediaStream? stream) {
    if (stream == null) {
      return;
    }
    if (renderer.srcObject != stream) {
      renderer.srcObject = stream;
    }
  }

  Future<void> _stopStreamTracks() async {
    final futures = <Future<void>>[];
    final localTracks = _localOriginatorStream?.getTracks() ?? const [];
    final remoteTracks = _remoteOriginatorStream?.getTracks() ?? const [];
    for (final track in localTracks) {
      futures.add(track.stop());
    }
    for (final track in remoteTracks) {
      futures.add(track.stop());
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  void _emitStateChange() {
    if (!_eventController.isClosed) {
      _eventController.add(this);
    }
  }

  void _dispose() {
    _media?.dispose();
    _media = null;
    _mediaFuture = null;
    _localOriginatorStream = null;
    _remoteOriginatorStream = null;
    _eventController.close();
  }
}

class InboundCall extends TelephoneCall {
  InboundCall._(super.service, super.call) : super._();

  Future<void> answer() => _service._answerCall(_call);
}

class OutboundCall extends TelephoneCall {
  OutboundCall._(super.service, super.call) : super._();
}

extension TelephoneCallEventHooks on TelephoneCall {
  StreamSubscription<TelephoneCall> onStateChanged(
    void Function(TelephoneCall call) cb,
  ) =>
      events.listen(cb);

  StreamSubscription<TelephoneCall> onCallInitiated(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.CALL_INITIATION}, cb);

  StreamSubscription<TelephoneCall> onStream(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.STREAM}, cb);

  StreamSubscription<TelephoneCall> onUnmuted(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.UNMUTED}, cb);

  StreamSubscription<TelephoneCall> onMuted(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.MUTED}, cb);

  StreamSubscription<TelephoneCall> onConnecting(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.CONNECTING}, cb);

  StreamSubscription<TelephoneCall> onProgress(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.PROGRESS}, cb);

  StreamSubscription<TelephoneCall> onFailed(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.FAILED}, cb);

  StreamSubscription<TelephoneCall> onEnded(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.ENDED}, cb);

  StreamSubscription<TelephoneCall> onAccepted(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.ACCEPTED}, cb);

  StreamSubscription<TelephoneCall> onConfirmed(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.CONFIRMED}, cb);

  StreamSubscription<TelephoneCall> onRefer(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.REFER}, cb);

  StreamSubscription<TelephoneCall> onHold(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.HOLD}, cb);

  StreamSubscription<TelephoneCall> onUnhold(
    void Function(TelephoneCall call) cb,
  ) =>
      _onStates(this, {CallStateEnum.UNHOLD}, cb);

  StreamSubscription<TelephoneCall> onRemoteHangup(
    void Function(TelephoneCall call) cb,
  ) =>
      onEnded((call) {
        if (!call._localHangupRequested) {
          cb(call);
        }
      });
}

StreamSubscription<TelephoneCall> _onStates(
  TelephoneCall call,
  Set<CallStateEnum> states,
  void Function(TelephoneCall call) cb,
) =>
    call.events.where((event) => states.contains(event.state)).listen(cb);
