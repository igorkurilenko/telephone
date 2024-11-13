import 'package:flutter/material.dart';

import '../../telephone.dart';

class IncomingCallWidget extends StatefulWidget {
  final SipService sipService;
  final Call call;

  const IncomingCallWidget({
    super.key,
    required this.sipService,
    required this.call,
  });

  @override
  State<IncomingCallWidget> createState() => _IncomingCallWidgetState();
}

class _IncomingCallWidgetState extends State<IncomingCallWidget>
    implements SipServiceListener {
  String get title => widget.call.remote_identity ?? '';

  @override
  void initState() {
    super.initState();
    widget.sipService.addSipServiceListener(this);
  }

  @override
  void deactivate() {
    widget.sipService.removeSipServiceListener(this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Row(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => widget.sipService.hangup(widget.call),
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    iconSize: 24,
                    padding: const EdgeInsets.all(8),
                    splashRadius: 30, // Makes button circular
                    constraints:
                        const BoxConstraints(minWidth: 50, minHeight: 50),
                    splashColor: Colors.redAccent,
                    highlightColor: Colors.red.withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => widget.sipService.answer(widget.call),
                    icon: const Icon(Icons.check),
                    color: Colors.white,
                    iconSize: 24,
                    padding: const EdgeInsets.all(8),
                    splashRadius: 30, // Makes button circular
                    constraints:
                        const BoxConstraints(minWidth: 50, minHeight: 50),
                    splashColor: Colors.blueAccent,
                    highlightColor: Colors.blue.withOpacity(0.3),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    // TODO: implement
  }

  @override
  void callStateChanged(Call call, CallState state) {
    // TODO: manage state of buttons
  }
}
