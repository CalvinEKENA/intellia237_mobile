import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../domain/otp_authentication.dart';

class OtpChannelSelector extends StatelessWidget {
  const OtpChannelSelector({
    required this.selected,
    required this.onSelected,
    this.whatsappSupported = true,
    super.key,
  });

  final OtpChannel selected;
  final ValueChanged<OtpChannel> onSelected;
  final bool whatsappSupported;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.otpChannelTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        RadioGroup<OtpChannel>(
          groupValue: selected,
          onChanged: (value) {
            if (value != null) onSelected(value);
          },
          child: Column(
            children: [
              if (whatsappSupported)
                RadioListTile<OtpChannel>(
                  key: const ValueKey('otp-channel-whatsapp'),
                  value: OtpChannel.whatsapp,
                  title: Text(l10n.otpWhatsapp),
                ),
              RadioListTile<OtpChannel>(
                key: const ValueKey('otp-channel-sms'),
                value: OtpChannel.sms,
                title: Text(l10n.otpSms),
                subtitle: Text(l10n.otpSmsFallback),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
