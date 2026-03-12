import 'package:beerer/theme/beer_theme.dart';
import 'package:flutter/material.dart';

/// Email verification banner shown when user hasn't verified email.
class EmailVerificationBanner extends StatelessWidget {
  const EmailVerificationBanner({
    super.key,
    required this.onResend,
  });

  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: BeerColors.primaryAmber,
      child: Row(
        children: [
          const Icon(
            Icons.email_outlined,
            color: BeerColors.background,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Check your inbox to verify your email.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BeerColors.background,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          TextButton(
            onPressed: onResend,
            child: Text(
              'Resend',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: BeerColors.background,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
