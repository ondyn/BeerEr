import 'package:beerer/theme/beer_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// In-app Privacy Policy screen.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = '20 March 2026';

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold);
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BeerEr — Privacy Policy',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: BeerColors.primaryAmber,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last updated: $_lastUpdated',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            // 1. Introduction
            _section(
              context,
              title: '1. Introduction',
              titleStyle: titleStyle,
              body:
                  'BeerEr ("the App") is a mobile application for tracking '
                  'beer consumption from a keg at social events. This Privacy '
                  'Policy explains what data we collect, how we use it, and '
                  'your rights regarding that data.\n\n'
                  'By using BeerEr you agree to the practices described in '
                  'this policy.',
              bodyStyle: bodyStyle,
            ),

            // 2. Data we collect
            _section(
              context,
              title: '2. Data We Collect',
              titleStyle: titleStyle,
              body: '',
              bodyStyle: bodyStyle,
            ),
            _subsection(
              context,
              title: '2.1 Account information',
              body:
                  'When you create an account we store your email address and '
                  'a display nickname in Firebase Authentication and Cloud '
                  'Firestore. If you sign in with a social provider '
                  '(e.g. Google) we receive the name and email associated '
                  'with that provider.',
              bodyStyle: bodyStyle,
            ),
            _subsection(
              context,
              title: '2.2 Profile data (optional)',
              body:
                  'You may optionally provide your weight, age, and gender '
                  'to enable the Blood-Alcohol Content (BAC) estimation '
                  'feature. These fields are stored in your Firestore user '
                  'document and are never shared with other users unless you '
                  'explicitly enable the "Show BAC estimate" visibility '
                  'setting.',
              bodyStyle: bodyStyle,
            ),
            _subsection(
              context,
              title: '2.3 Keg session & pour data',
              body:
                  'When you create or join a keg session we store the session '
                  'details (beer name, volume, price, alcohol %, '
                  'participants). Each pour you log records the volume, '
                  'timestamp, and which user poured for whom. This data is '
                  'visible to all participants of the session.',
              bodyStyle: bodyStyle,
            ),
            _subsection(
              context,
              title: '2.4 Guest participants',
              body:
                  'Session creators can add guest (manual) participants by '
                  'nickname. Guest data consists only of a nickname and is '
                  'stored in a Firestore sub-collection of the session. When '
                  'a real user joins and merges with a guest, the guest '
                  'record is deleted and their pours are reassigned.',
              bodyStyle: bodyStyle,
            ),
            _subsection(
              context,
              title: '2.5 Device tokens',
              body:
                  'If you allow push notifications we store your Firebase '
                  'Cloud Messaging (FCM) device token in your user document. '
                  'This token is used solely to deliver notifications about '
                  'session events (e.g. someone poured for you, keg nearly '
                  'empty, keg done).',
              bodyStyle: bodyStyle,
            ),

            // 3. How we use your data
            _section(
              context,
              title: '3. How We Use Your Data',
              titleStyle: titleStyle,
              body:
                  '• Display your nickname and pour history to session '
                  'participants.\n'
                  '• Calculate per-user statistics (drinking rate, cost '
                  'share, keg depletion estimate).\n'
                  '• Estimate BAC on your device only — the calculated BAC '
                  'value is never stored or transmitted.\n'
                  '• Send push notifications for session events you have '
                  'opted into.\n'
                  '• Generate a cost summary (bill review) at the end of '
                  'a session.',
              bodyStyle: bodyStyle,
            ),

            // 4. BAC calculation
            _section(
              context,
              title: '4. BAC Estimation',
              titleStyle: titleStyle,
              body:
                  'BAC is estimated on your device using the Widmark formula '
                  'based on your locally stored weight, age, gender, and '
                  'pour history. The calculated BAC value is never written '
                  'to Firestore or any server. It is for informational '
                  'purposes only and must not be used to determine fitness '
                  'to drive or operate machinery.',
              bodyStyle: bodyStyle,
            ),

            // 5. Third-party services
            _section(
              context,
              title: '5. Third-Party Services',
              titleStyle: titleStyle,
              body: '',
              bodyStyle: bodyStyle,
            ),
            _subsection(
              context,
              title: '5.1 Firebase (Google)',
              body:
                  'BeerEr uses Firebase Authentication, Cloud Firestore, '
                  'Cloud Functions, and Firebase Cloud Messaging. Data is '
                  'processed under Google\u2019s terms of service and data '
                  'processing agreements. Firebase servers are located in '
                  'the EU (europe-west1). For details see '
                  'https://firebase.google.com/support/privacy.',
              bodyStyle: bodyStyle,
            ),
            _subsection(
              context,
              title: '5.2 BeerWeb.cz',
              body:
                  'When you search for a beer while creating a keg session, '
                  'BeerEr may query the public search API at beerweb.cz '
                  '(a Czech beer database) through a server-side Cloud '
                  'Function. Only the search term you type is sent to '
                  'beerweb.cz — no personal data is transmitted. '
                  'BeerWeb.cz is an independent third-party service; please '
                  'refer to their website for their privacy practices.',
              bodyStyle: bodyStyle,
            ),
            _subsection(
              context,
              title: '5.3 Revolut',
              body:
                  'The App contains an optional "Tip via Revolut" link '
                  '(revolut.me/hnyko) that opens in your browser or the '
                  'Revolut app. BeerEr does not process any payment data. '
                  'Any transaction you make is handled entirely by Revolut '
                  'under their own terms and privacy policy.',
              bodyStyle: bodyStyle,
            ),

            // 6. Data sharing
            _section(
              context,
              title: '6. Data Sharing',
              titleStyle: titleStyle,
              body:
                  'Your nickname, pour history, and (if you opt in) stats '
                  'and BAC estimate are visible to other participants of '
                  'the same keg session. We do not sell, rent, or share '
                  'your personal data with any third parties beyond the '
                  'service providers listed in Section 5.',
              bodyStyle: bodyStyle,
            ),

            // 7. Data retention
            _section(
              context,
              title: '7. Data Retention',
              titleStyle: titleStyle,
              body:
                  'Session and pour data is retained as long as the session '
                  'exists. The session creator can delete a session, which '
                  'removes all associated pours, guest participants, and '
                  'joint accounts.\n\n'
                  'Your user profile is retained until you delete your '
                  'account. You can request account deletion at any time '
                  'through the app settings.',
              bodyStyle: bodyStyle,
            ),

            // 8. Offline data
            _section(
              context,
              title: '8. Offline Data',
              titleStyle: titleStyle,
              body:
                  'BeerEr uses Firebase\u2019s built-in offline persistence, '
                  'which caches data locally on your device so the app '
                  'works without an internet connection. Cached data is '
                  'automatically synced when connectivity is restored. No '
                  'custom peer-to-peer sync mechanism is used.',
              bodyStyle: bodyStyle,
            ),

            // 9. Security
            _section(
              context,
              title: '9. Security',
              titleStyle: titleStyle,
              body:
                  'All communication between the app and Firebase is '
                  'encrypted via TLS. Firestore security rules enforce '
                  'that users can only read and write data they are '
                  'authorised to access. API keys for third-party services '
                  '(BeerWeb.cz) are stored server-side in Cloud Function '
                  'environment configuration and are never exposed to '
                  'the client app.',
              bodyStyle: bodyStyle,
            ),

            // 10. Children
            _section(
              context,
              title: '10. Children',
              titleStyle: titleStyle,
              body:
                  'BeerEr is not intended for use by anyone under the legal '
                  'drinking age in their jurisdiction. We do not knowingly '
                  'collect data from minors. If you believe a minor has '
                  'created an account, please contact us so we can remove '
                  'the data.',
              bodyStyle: bodyStyle,
            ),

            // 11. Your rights
            _section(
              context,
              title: '11. Your Rights',
              titleStyle: titleStyle,
              body:
                  'Under applicable data protection laws (including the EU '
                  'General Data Protection Regulation) you have the right '
                  'to:\n'
                  '• Access the personal data we hold about you.\n'
                  '• Correct inaccurate data via your profile settings.\n'
                  '• Delete your account and associated data.\n'
                  '• Withdraw consent for optional data processing '
                  '(e.g. BAC-related fields, push notifications).\n\n'
                  'To exercise these rights, use the in-app settings or '
                  'contact us at the address below.',
              bodyStyle: bodyStyle,
            ),

            // 12. Changes to this policy
            _section(
              context,
              title: '12. Changes to This Policy',
              titleStyle: titleStyle,
              body:
                  'We may update this Privacy Policy from time to time. '
                  'The "Last updated" date at the top of this page will '
                  'be revised accordingly. Continued use of the App after '
                  'changes constitutes acceptance of the updated policy.',
              bodyStyle: bodyStyle,
            ),

            // 13. Contact
            _section(
              context,
              title: '13. Contact',
              titleStyle: titleStyle,
              body:
                  'If you have questions about this Privacy Policy or '
                  'your data, please contact:\n\n'
                  'BeerEr Developer\n'
                  'Email: ondrej.hnyk@gmail.com',
              bodyStyle: bodyStyle,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    TextStyle? titleStyle,
    required String body,
    TextStyle? bodyStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(body, style: bodyStyle),
          ],
        ],
      ),
    );
  }

  Widget _subsection(
    BuildContext context, {
    required String title,
    required String body,
    TextStyle? bodyStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(body, style: bodyStyle),
        ],
      ),
    );
  }
}
