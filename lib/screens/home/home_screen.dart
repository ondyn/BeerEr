import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/screens/keg/qr_scanner_screen.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/local_profile.dart';
import 'package:beerer/widgets/avatar_icon.dart';
import 'package:beerer/widgets/session_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Home screen — entry point listing active and past keg sessions.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final firebaseUser = authState.value;
    final allSessions = ref.watch(watchAllSessionsProvider);
    final currentUserId = firebaseUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.beerer),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: BeerColors.surfaceVariant,
              child: Icon(
                Icons.person,
                size: 20,
                color: BeerColors.primaryAmber,
              ),
            ),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      drawer: _BeerErDrawer(user: firebaseUser),
      body: Column(
        children: [
          // Session list
          Expanded(
            child: allSessions.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.sports_bar_outlined,
                          size: 80,
                          color: BeerColors.surfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noKegSessionsYet,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: BeerColors.onSurfaceSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.tapPlusToCreate,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                final active = sessions
                    .where((s) =>
                        s.status.name == 'created' ||
                        s.status.name == 'active' ||
                        s.status.name == 'paused')
                    .toList();

                if (active.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.sports_bar_outlined,
                          size: 80,
                          color: BeerColors.surfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noActiveKegSessions,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: BeerColors.onSurfaceSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.tapPlusToCreateNew,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16,
                  ),
                  children: [
                    for (final session in active)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SessionCardWithCount(
                          session: session,
                          isOwner: session.creatorId == currentUserId,
                          highlighted: true,
                          onTap: () =>
                              context.push('/keg/${session.id}'),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: BeerColors.primaryAmber,
                ),
              ),
              error: (e, _) => Center(
                child: Text(AppLocalizations.of(context)!.error(e.toString())),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: BeerColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FloatingActionButton.extended(
                heroTag: 'join_keg',
                onPressed: () => _showJoinDialog(context),
                icon: const Icon(Icons.qr_code_scanner),
                label: FittedBox(
                  child: Text(AppLocalizations.of(context)!.joinKegSession),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: FloatingActionButton.extended(
                heroTag: 'new_keg',
                onPressed: () => context.push('/keg/new'),
                icon: const Icon(Icons.add),
                label: FittedBox(
                  child: Text(AppLocalizations.of(context)!.newKegSession),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a dialog where the user can paste a beerer:// link or type a session ID.
void _showJoinDialog(BuildContext context) {
  final controller = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.sports_bar, color: BeerColors.primaryAmber),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(ctx)!.joinAKegSession),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(ctx)!.pasteInviteLinkOrId,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(ctx)!.inviteLinkHint,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  tooltip: AppLocalizations.of(ctx)!.pasteFromClipboard,
                  onPressed: () async {
                    final clip = await Clipboard.getData(Clipboard.kTextPlain);
                    if (clip?.text != null) {
                      controller.text = clip!.text!;
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final sessionId = await Navigator.of(ctx).push<String>(
                    MaterialPageRoute(
                      builder: (_) => const QrScannerScreen(),
                    ),
                  );
                  if (sessionId != null && ctx.mounted) {
                    Navigator.pop(ctx);
                    context.push('/join/$sessionId');
                  }
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(AppLocalizations.of(ctx)!.scanQrCode),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppLocalizations.of(ctx)!.cancel),
        ),
        FilledButton(
          onPressed: () {
            final sessionId = _extractSessionId(controller.text.trim());
            if (sessionId == null) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(ctx)!.invalidLinkOrId),
                ),
              );
              return;
            }
            Navigator.pop(ctx);
            context.push('/join/$sessionId');
          },
          child: Text(AppLocalizations.of(ctx)!.join),
        ),
      ],
    ),
  );
}

/// Extracts a session ID from either:
///   - a raw session ID string  (e.g. "abc123")
///   - a beerer:// URI          (e.g. "beerer://join/abc123")
String? _extractSessionId(String input) {
  if (input.isEmpty) return null;

  // Try to parse as URI first
  final uri = Uri.tryParse(input);
  if (uri != null && uri.scheme == 'beerer' && uri.host == 'join') {
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    return (id != null && id.isNotEmpty) ? id : null;
  }

  // Assume raw session ID — must not contain whitespace or slashes
  final clean = input.replaceAll(RegExp(r'\s'), '');
  if (clean.isNotEmpty && !clean.contains('/')) return clean;

  return null;
}

/// Navigation drawer.
class _BeerErDrawer extends ConsumerWidget {
  const _BeerErDrawer({this.user});

  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = user != null
        ? ref.watch(watchCurrentUserProvider(user!.uid)).asData?.value
        : null;
    final displayName = appUser?.nickname.isNotEmpty == true
        ? appUser!.nickname
        : user?.email ?? AppLocalizations.of(context)!.guest;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: BeerColors.surfaceVariant,
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AvatarCircle(
                    displayName: displayName,
                    avatarIcon: appUser?.avatarIcon,
                    radius: 30,
                    isHighlighted: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(AppLocalizations.of(context)!.home),
            onTap: () {
              Navigator.pop(context);
              context.go('/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(AppLocalizations.of(context)!.pastSessions),
            onTap: () {
              Navigator.pop(context);
              context.push('/sessions/history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(AppLocalizations.of(context)!.settings),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppLocalizations.of(context)!.about),
            onTap: () {
              Navigator.pop(context);
              context.push('/about');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(AppLocalizations.of(context)!.signOut),
            onTap: () async {
              Navigator.pop(context);
              await LocalProfile.instance.clear();
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/welcome');
            },
          ),
        ],
      ),
    );
  }
}

/// Wraps [SessionCard] and watches the participant count from Firestore
/// so the home-screen list always shows the correct number of participants.
class _SessionCardWithCount extends ConsumerWidget {
  const _SessionCardWithCount({
    required this.session,
    required this.isOwner,
    this.highlighted = false,
    this.onTap,
  });

  final KegSession session;
  final bool isOwner;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantIdsAsync =
        ref.watch(watchParticipantIdsProvider(session.id));
    final participantCount =
        participantIdsAsync.asData?.value.length ?? 0;

    return SessionCard(
      session: session,
      participantCount: participantCount,
      isOwner: isOwner,
      highlighted: highlighted,
      onTap: onTap,
    );
  }
}
