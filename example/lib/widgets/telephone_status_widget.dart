import 'package:flutter/material.dart';
import 'package:telephone/telephone.dart';

class TelephoneStatusWidget extends StatelessWidget {
  const TelephoneStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final telephone = Telephone.of(context);
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<TransportState>(
            stream: telephone.transportStates,
            builder: (context, snapshot) {
              final transportState =
                  snapshot.data?.state ?? TransportStateEnum.NONE;
              return Text('Transport: ${transportState.name}');
            },
          ),
          const SizedBox(width: 12),
          StreamBuilder<RegistrationState>(
            stream: telephone.registrationStates,
            builder: (context, snapshot) {
              final registrationState =
                  snapshot.data?.state ?? RegistrationStateEnum.NONE;
              return Text('Sip: ${registrationState.name}');
            },
          ),
        ],
      ),
    );
  }
}
