import 'package:example/config.dart';
import 'package:flutter/material.dart';
import 'package:telephone/telephone.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,

      // 1. Wrap with Telephone
      home: Telephone(
        child: TelephoneExample(),
      ),
    ),
  );
}

class TelephoneExample extends StatefulWidget {
  const TelephoneExample({super.key});

  @override
  State<TelephoneExample> createState() => _TelephoneExampleState();
}

class _TelephoneExampleState extends State<TelephoneExample>
    implements SipServiceListener {
  TelephoneState get telephone => Telephone.of(context);

  @override
  void initState() {
    super.initState();

    // 2. Connect to the sip endpoint
    telephone.connect(
      endpoint: kSipEndpoint,
      account: kSipAccount,
    );

    telephone.addSipServiceListener(this);
  }

  @override
  void dispose() {
    telephone.removeSipServiceListener(this);
    telephone.disconnect();
    super.dispose();
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() {});
  }

  @override
  void callStateChanged(Call call, CallState state) {}

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.phone_outlined),

                // 3. Call
                onPressed:
                    telephone.registered ? () => telephone.call('400') : null,
              ),
            )
          ],
        ),
        body: const Center(
          child: Text('Hello Telephone!'),
        ),
      );

  @override
  void transportStateChanged(TransportState state) {}
}
