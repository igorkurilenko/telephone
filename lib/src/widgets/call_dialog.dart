import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../telephone.dart';

class CallDialog extends StatefulWidget {
  final SipService sipService;
  final Call call;

  const CallDialog({
    super.key,
    required this.sipService,
    required this.call,
  });

  @override
  State<CallDialog> createState() => _CallDialogState();
}

class _CallDialogState extends State<CallDialog> implements SipServiceListener {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  String get callTitle => widget.call.remote_identity ?? '';

  @override
  void initState() {
    super.initState();
    _initRenderers();
    widget.sipService.addSipServiceListener(this);
  }

  @override
  void deactivate() {
    widget.sipService.removeSipServiceListener(this);
    _disposeRenderers();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Text(
              callTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (kIsWeb)
            Offstage(
              offstage: true,
              child: RTCVideoView(_remoteRenderer),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: () {
            // TODO: stop tracks in sipService.hangup
            // when flutter_webrtc bug will be fixed
            _stopStreamTracks();
            widget.sipService.hangup(widget.call);
          },
          shape: const CircleBorder(),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          child: const Icon(Icons.call_end),
        ),
      ),
    );
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {});
  }

  @override
  void callStateChanged(Call call, CallState callState) {
    switch (callState.state) {
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        _handleCallEnded(callState);
      case CallStateEnum.STREAM:
        _handleCallStream(callState);
      default:
        break;
    }
  }

  void _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _disposeRenderers() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  void _stopStreamTracks() {
    _localStream?.getTracks().forEach((t) => t.stop());
    _remoteStream?.getTracks().forEach((t) => t.stop());
  }

  void _handleCallEnded(CallState callState) => Navigator.of(context).pop();

  void _handleCallStream(CallState callState) {
    if (callState.originator == Originator.local) {
      _localRenderer.srcObject = callState.stream;

      if (!kIsWeb && !WebRTC.platformIsDesktop) {
        callState.stream?.getAudioTracks().first.enableSpeakerphone(false);
      }
    }

    if (callState.originator == Originator.remote) {
      _remoteRenderer.srcObject = callState.stream;
    }
  }
}
