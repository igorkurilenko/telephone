# Telephone

A lightweight SIP wrapper around `sip_ua_webrtc_fixed` that exposes simple
call lifecycle APIs while keeping UI fully in your app.

## Installation

Install via `flutter pub`:

```bash
flutter pub add telephone
```

## Usage

Step-by-step usage (UI is up to you; see `example/` for a full flow):

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:telephone/telephone.dart';

// Replace with your SIP endpoint/account details.
final kSipEndpoint = SipEndpoint(
  host: 'sip.example.com',
  port: 5060,
  wsProtocol: 'wss',
  wsPort: 8089,
  wsPath: '/ws',
  webSocketTransport: true,
);

final kSipAccount = SipAccount(
  username: '1001',
  password: 'secret',
  displayName: 'Alice',
);

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,

    // 1. Wrap with Telephone
    home: Telephone(
      child: TelephoneExample(),
    ),
  ));
}

class TelephoneExample extends StatefulWidget {
  const TelephoneExample({super.key});

  @override
  State<TelephoneExample> createState() => _TelephoneExampleState();
}

class _TelephoneExampleState extends State<TelephoneExample> {
  TelephoneState get telephone => Telephone.of(context);
  StreamSubscription<InboundCall>? _ringingSubscription;

  @override
  void initState() {
    super.initState();

    // 2. Connect to the SIP endpoint
    telephone.connect(
      endpoint: kSipEndpoint,
      account: kSipAccount,
    );

    // 3. Listen for inbound ringing calls
    _ringingSubscription = telephone.onRinging((call) {
      // Show your toast or banner here.
      call.onAccepted((_) {
        // Open your call dialog here.
      });
      call.onEnded((_) {
        // Clean up UI here.
      });
      call.onFailed((_) {
        // Clean up UI here.
      });
    });
  }

  @override
  void dispose() {
    _ringingSubscription?.cancel();
    telephone.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: StreamBuilder<RegistrationState>(
                stream: telephone.registrationStates,
                builder: (context, snapshot) {
                  final canCall = telephone.registered;
                  return IconButton(
                    icon: const Icon(Icons.phone_outlined),

                    // 4. Dial
                    onPressed: canCall
                        ? () async {
                            final call = await telephone.dial('400');
                            call.onProgress((_) {});
                            call.onConfirmed((_) {});
                            call.onRemoteHangup((_) {});
                            call.onFailed((_) {});
                            call.onEnded((_) {});
                          }
                        : null,
                  );
                },
              ),
            )
          ],
        ),
        body: const Center(
          child: Text('Hello Telephone!'),
        ),
      );
}
```

Notes:
- Audio streams are managed internally; your UI does not need `flutter_webrtc`.
- Use `call.onProgress/onConfirmed/onEnded/onFailed` to drive your dialogs/toasts.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
