part of '../telephone.dart';

/// Configuration for CallManager behavior
class CallManagerConfig {
  /// Automatically answer incoming calls
  final bool autoAnswer;

  /// Delay before auto-answering (useful for setup)
  final Duration autoAnswerDelay;

  const CallManagerConfig({
    this.autoAnswer = false,
    this.autoAnswerDelay = Duration.zero,
  });
}

/// Callback types
typedef OnIncomingCallCallback = void Function(CallSession session);
typedef OnCallAcceptedCallback = void Function(CallSession session);
typedef OnCallEndedCallback = void Function(CallSession session);

/// Manages all active calls and provides high-level call orchestration
class CallManager extends ChangeNotifier implements SipServiceListener {
  final SipService _sipService;
  final CallManagerConfig config;

  // Call sessions
  CallSession? _activeCall;
  final Map<Call, CallSession> _sessions = {};

  // State
  bool _isReadyToReceive = false;

  // Callbacks
  OnIncomingCallCallback? onIncomingCall;
  OnCallAcceptedCallback? onCallAccepted;
  OnCallEndedCallback? onCallEnded;

  CallManager({
    required SipService sipService,
    this.config = const CallManagerConfig(),
    this.onIncomingCall,
    this.onCallAccepted,
    this.onCallEnded,
  }) : _sipService = sipService {
    _sipService.addSipServiceListener(this);
  }

  // Getters
  CallSession? get activeCall => _activeCall;
  bool get hasActiveCall => _activeCall != null;
  bool get isReadyToReceive => _isReadyToReceive;
  List<CallSession> get incomingCalls =>
      _sessions.values.where((s) => s.isIncoming && !s.hasEnded).toList();
  bool get hasIncomingCall => incomingCalls.isNotEmpty;

  /// Set whether the app is ready to receive calls
  void setReadyToReceive(bool ready) {
    if (_isReadyToReceive != ready) {
      _isReadyToReceive = ready;
      notifyListeners();
    }
  }

  /// Get or create a CallSession for a Call
  CallSession _getOrCreateSession(Call call) {
    return _sessions.putIfAbsent(
      call,
      () => CallSession(call: call, sipService: _sipService),
    );
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    // Pass through to listeners if needed
    notifyListeners();
  }

  @override
  void callStateChanged(Call call, CallState callState) {
    final session = _getOrCreateSession(call);
    session.updateState(callState);

    switch (callState.state) {
      case CallStateEnum.CALL_INITIATION:
        _handleCallInitiation(session);
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        _handleCallAccepted(session);
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        _handleCallEnded(session);
        break;
      default:
        break;
    }

    notifyListeners();
  }

  void _handleCallInitiation(CallSession session) {
    if (session.isIncoming) {
      // Incoming call
      if (!_isReadyToReceive) {
        // Decline when app is not ready to receive calls.
        session.hangup();
        return;
      }

      // Notify app about incoming call
      onIncomingCall?.call(session);

      // Auto-answer if configured
      if (config.autoAnswer) {
        if (config.autoAnswerDelay > Duration.zero) {
          Future.delayed(config.autoAnswerDelay, () {
            if (!session.hasEnded) {
              session.answer();
            }
          });
        } else {
          session.answer();
        }
      }
    } else {
      // Outgoing call
      _activeCall = session;
    }
  }

  void _handleCallAccepted(CallSession session) {
    _activeCall = session;
    onCallAccepted?.call(session);
  }

  void _handleCallEnded(CallSession session) {
    if (_activeCall == session) {
      _activeCall = null;
    }

    onCallEnded?.call(session);

    // Clean up session after a delay to allow UI to show end state
    Future.delayed(const Duration(seconds: 5), () {
      _sessions.remove(session.call);
      session.dispose();
    });
  }

  /// Make an outgoing call
  Future<bool> call(String target) async {
    return await _sipService.call(target);
  }

  @override
  void dispose() {
    _sipService.removeSipServiceListener(this);
    for (var session in _sessions.values) {
      session.dispose();
    }
    _sessions.clear();
    super.dispose();
  }
}
