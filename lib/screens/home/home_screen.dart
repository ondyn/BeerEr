import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/theme/beer_theme.dart';
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
        title: const Text('BeerEr'),
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
            onPressed: () => context.go('/profile'),
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
                          'No keg sessions yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: BeerColors.onSurfaceSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create your first keg session!',
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
                          'No active keg sessions',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: BeerColors.onSurfaceSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create a new keg session',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final session in active)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SessionCardWithCount(
                          session: session,
                          isOwner: session.creatorId == currentUserId,
                          highlighted: true,
                          onTap: () =>
                              context.go('/keg/${session.id}'),
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
                child: Text('Error: $e'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join_keg',
            onPressed: () => _showJoinDialog(context),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Join Keg Session'),
            backgroundColor: BeerColors.surfaceVariant,
            foregroundColor: BeerColors.primaryAmber,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'new_keg',
            onPressed: () => context.go('/keg/new'),
            icon: const Icon(Icons.add),
            label: const Text('New Keg Session'),
          ),
        ],
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
      title: const Row(
        children: [
          Icon(Icons.sports_bar, color: BeerColors.primaryAmber),
          SizedBox(width: 8),
          Text('Join a Keg Session'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste the invite link or enter the session ID:',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'beerer://join/... or session ID',
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste),
                tooltip: 'Paste from clipboard',
                onPressed: () async {
                  final clip = await Clipboard.getData(Clipboard.kTextPlain);
                  if (clip?.text != null) {
                    controller.text = clip!.text!;
                  }
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final sessionId = _extractSessionId(controller.text.trim());
            if (sessionId == null) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Invalid link or session ID'),
                ),
              );
              return;
            }
            Navigator.pop(ctx);
            context.go('/join/$sessionId');
          },
          child: const Text('Join'),
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
        : user?.email ?? 'Guest';
    final avatarLetter = displayName[0].toUpperCase();

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
                context.go('/profile');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: BeerColors.primaryAmber,
                    child: Text(
                      avatarLetter,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: BeerColors.background),
                    ),
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
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go('/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Past Sessions'),
            onTap: () {
              Navigator.pop(context);
              context.go('/sessions/history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.go('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              context.go('/about');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              Navigator.pop(context);
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
