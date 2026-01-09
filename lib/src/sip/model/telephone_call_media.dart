part of '../../telephone.dart';

class TelephoneCallMedia {
  TelephoneCallMedia._(
    this._call, {
    required bool enableSpeakerphone,
  }) : _enableSpeakerphone = enableSpeakerphone;

  final TelephoneCall _call;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  bool _disposed = false;
  bool _initialized = false;
  bool _enableSpeakerphone;

  RTCVideoRenderer get localRenderer {
    final renderer = _localRenderer;
    assert(renderer != null, 'TelephoneCallMedia has not been initialized');
    return renderer!;
  }

  RTCVideoRenderer get remoteRenderer {
    final renderer = _remoteRenderer;
    assert(renderer != null, 'TelephoneCallMedia has not been initialized');
    return renderer!;
  }

  Future<void> initialize() async {
    if (_disposed || _initialized) {
      return;
    }
    final localRenderer = RTCVideoRenderer();
    final remoteRenderer = RTCVideoRenderer();
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
    } catch (error) {
      localRenderer.dispose();
      remoteRenderer.dispose();
      rethrow;
    }
    _localRenderer = localRenderer;
    _remoteRenderer = remoteRenderer;
    _initialized = true;
  }

  void setSpeakerphone(bool enable) {
    _enableSpeakerphone = enable;
    _applySpeakerphone();
  }

  Future<void> stopTracks() => _call._stopStreamTracks();

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _call._media = null;
    _call._mediaFuture = null;
    unawaited(stopTracks());
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
  }

  void _applySpeakerphone() {
    if (kIsWeb || WebRTC.platformIsDesktop) {
      return;
    }
    final stream = _call.localOriginatorStream;
    if (stream == null) {
      return;
    }
    final tracks = stream.getAudioTracks();
    if (tracks.isEmpty) {
      return;
    }
    tracks.first.enableSpeakerphone(_enableSpeakerphone);
  }
}
