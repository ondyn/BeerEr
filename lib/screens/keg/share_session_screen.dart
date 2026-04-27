import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Share session screen — QR code + deep link + share intents.
class ShareSessionScreen extends StatelessWidget {
  const ShareSessionScreen({super.key, required this.sessionId});

  final String sessionId;

  /// Canonical join link shared to other apps.
  /// Format: https://ondyn-beerer.web.app/join/[sessionId]
  ///
  /// This is clickable in chat apps (e.g. WhatsApp). The hosted join page
  /// then opens the app via custom scheme and falls back to Play Store.
  String get _joinLink => 'https://ondyn-beerer.web.app/join/$sessionId';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context)!.shareKegSession),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.inviteFriendsToJoin,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            // QR Code
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _joinLink,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Join link
            Text(
              _joinLink,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BeerColors.primaryAmber,
                  ),
            ),
            const SizedBox(height: 16),
            // Copy link
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _joinLink));
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.linkCopied)),
                );
              },
              icon: const Icon(Icons.copy),
              label: Text(AppLocalizations.of(context)!.copyLink),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: AppLocalizations.of(context)!.joinMyKegParty(_joinLink)),
              ),
              icon: const Icon(Icons.share),
              label: Text(AppLocalizations.of(context)!.shareLink),
            ),
          ],
        ),
      ),
    );
  }
}
