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

  /// Deep link that opens the app directly on Android & iOS.
  /// Format: beerer://join/[sessionId]
  String get _deepLink => 'beerer://join/$sessionId';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go('/keg/$sessionId'),
        ),
        title: const Text('Share Keg Session'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Invite friends to join',
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
                  data: _deepLink,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Deep link
            Text(
              _deepLink,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BeerColors.primaryAmber,
                  ),
            ),
            const SizedBox(height: 16),
            // Copy link
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _deepLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied!')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy link'),
            ),
            const SizedBox(height: 16),
            // Share via
            Text(
              'Share via…',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: 'Join my keg party! $_deepLink'),
                    ),
                    child: const Text('WhatsApp'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: 'Join my keg party! $_deepLink'),
                    ),
                    child: const Text('Messages'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: 'Join my keg party! $_deepLink'),
                    ),
                    child: const Text('Mail'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: 'Join my keg party! $_deepLink'),
                    ),
                    child: const Text('Other…'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
