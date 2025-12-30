part of '../telephone.dart';

/// Manages a single call's lifecycle, streams, and controls
class CallSession extends ChangeNotifier {
  final Call call;
  final SipService _sipService;

  // Stream management
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // Renderers for audio/video playback
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;

  // Call state
  CallStateEnum _state = CallStateEnum.NONE;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  Duration _duration = Duration.zero;
  Timer? _timer;

  CallSession({
    required this.call,
    required SipService sipService,
  }) : _sipService = sipService {
    _initializeRenderers();
  }

  // Getters
  String get callerId => call.remote_identity ?? 'Unknown';
  bool get isIncoming => CallDirection.isIncoming(call);
  bool get isOutgoing => CallDirection.isOutgoing(call);
  CallStateEnum get state => _state;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  Duration get duration => _duration;
  bool get isActive =>
      _state != CallStateEnum.ENDED && _state != CallStateEnum.FAILED;
  bool get hasEnded =>
      _state == CallStateEnum.ENDED || _state == CallStateEnum.FAILED;

  // Stream getters
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _renderersInitialized = true;
    if (_localStream != null) {
      _localRenderer.srcObject = _localStream;
    }
    if (_remoteStream != null) {
      _remoteRenderer.srcObject = _remoteStream;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _duration = Duration(seconds: timer.tick);
      notifyListeners();
    });
  }

  /// Update call state and handle stream setup
  void updateState(CallState callState) {
    final oldState = _state;
    _state = callState.state;

    // Handle stream events - separate local and remote
    if (callState.state == CallStateEnum.STREAM && callState.stream != null) {
      _handleStream(callState);
    }

    if (_timer == null &&
        (_state == CallStateEnum.ACCEPTED ||
            _state == CallStateEnum.CONFIRMED)) {
      _startTimer();
    }

    // Stop timer when call ends
    if (hasEnded && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    if (oldState != _state) {
      notifyListeners();
    }
  }

  void _handleStream(CallState callState) {
    if (callState.stream == null) return;

    if (callState.originator == Originator.local) {
      _localStream = callState.stream;
      if (_renderersInitialized) {
        _localRenderer.srcObject = _localStream;
      }
    } else if (callState.originator == Originator.remote) {
      _remoteStream = callState.stream;
      if (_renderersInitialized) {
        _remoteRenderer.srcObject = _remoteStream;
      }
    }

    notifyListeners();
  }

  /// Answer the call
  Future<void> answer() async {
    await _sipService.answer(call);
  }

  /// Hang up the call
  void hangup() {
    _sipService.hangup(call);
  }

  /// Toggle mute state
  Future<void> toggleMute() async {
    if (_localStream == null) return;

    final audioTracks = _localStream!.getAudioTracks();
    if (audioTracks.isEmpty) return;

    _isMuted = !_isMuted;

    for (var track in audioTracks) {
      track.enabled = !_isMuted;
    }

    notifyListeners();
  }

  /// Set mute state explicitly
  Future<void> setMuted(bool muted) async {
    if (_isMuted == muted) return;
    await toggleMute();
  }

  /// Toggle speaker state
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  /// Set speaker state explicitly
  Future<void> setSpeaker(bool speakerOn) async {
    if (_isSpeakerOn == speakerOn) return;
    await toggleSpeaker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }
}
