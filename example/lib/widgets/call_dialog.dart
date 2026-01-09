import 'package:flutter/material.dart';

import 'package:telephone/telephone.dart';

class CallDialog extends StatefulWidget {
  final TelephoneCall call;

  const CallDialog({
    super.key,
    required this.call,
  });

  @override
  State<CallDialog> createState() => _CallDialogState();
}

class _CallDialogState extends State<CallDialog> {
  String get callTitle => widget.call.remoteIdentity ?? '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: StreamBuilder<TelephoneCall>(
            stream: widget.call.events,
            initialData: widget.call,
            builder: (context, snapshot) {
              final call = snapshot.data ?? widget.call;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    callTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Call: ${call.state.name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: FloatingActionButton(
            onPressed: () async {
              await widget.call.hangup();
            },
            shape: const CircleBorder(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            child: const Icon(Icons.call_end),
          ),
        ),
      );
}
