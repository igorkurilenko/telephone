import 'package:flutter/material.dart';

import 'package:telephone/telephone.dart';

class InboundCallWidget extends StatelessWidget {
  final InboundCall call;
  final VoidCallback onReject;
  final VoidCallback onAccept;

  const InboundCallWidget({
    super.key,
    required this.call,
    required this.onReject,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final title = call.remoteIdentity ?? '';
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
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    iconSize: 24,
                    padding: const EdgeInsets.all(8),
                    splashRadius: 30, // Makes button circular
                    constraints:
                        const BoxConstraints(minWidth: 50, minHeight: 50),
                    splashColor: Colors.redAccent,
                    highlightColor: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check),
                    color: Colors.white,
                    iconSize: 24,
                    padding: const EdgeInsets.all(8),
                    splashRadius: 30, // Makes button circular
                    constraints:
                        const BoxConstraints(minWidth: 50, minHeight: 50),
                    splashColor: Colors.blueAccent,
                    highlightColor: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
