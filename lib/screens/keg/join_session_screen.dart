import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:beerer/repositories/user_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Join session screen — reached via deep link / QR code.
class JoinSessionScreen extends ConsumerStatefulWidget {
  const JoinSessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<JoinSessionScreen> createState() =>
      _JoinSessionScreenState();
}

class _JoinSessionScreenState extends ConsumerState<JoinSessionScreen> {
  bool _showStats = true;
  bool _showBac = false;
  bool _isJoining = false;

  /// If the user chose to merge with a manual user, this holds the id.
  String? _mergeWithManualUserId;

  Future<void> _join() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/welcome');
      return;
    }

    setState(() => _isJoining = true);

    try {
      final kegRepo = ref.read(kegRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      // Preserve existing nickname from profile; only update preferences.
      // Fall back to displayName or the local part of the email so the
      // participant chip never shows "?".
      final existingUser = await userRepo.getUser(user.uid);
      final existingNickname =
          (existingUser?.nickname.trim().isNotEmpty ?? false)
              ? existingUser!.nickname
              : null;
      final fallbackNickname =
          user.displayName?.trim().isNotEmpty == true
              ? user.displayName!
              : (user.email?.split('@').first ?? '');
      await userRepo.createOrUpdateUser(AppUser(
        id: user.uid,
        nickname: existingNickname ?? fallbackNickname,
        email: user.email ?? '',
        preferences: {
          'show_stats': _showStats,
          'show_bac': _showBac,
        },
      ));

      // Add participant
      await kegRepo.addParticipant(widget.sessionId, user.uid);

      // Merge with manual user if selected.
      if (_mergeWithManualUserId != null) {
        await kegRepo.mergeManualUser(
          sessionId: widget.sessionId,
          manualUserId: _mergeWithManualUserId!,
          realUserId: user.uid,
        );
      }

      if (mounted) context.go('/keg/${widget.sessionId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync =
        ref.watch(watchSessionProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Session not found'));
          }
          return _buildContent(context, session);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: BeerColors.primaryAmber,
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, KegSession session) {
    final manualUsersAsync =
        ref.watch(watchManualUsersProvider(session.id));
    final manualUsers = manualUsersAsync.asData?.value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "You're invited to a party!",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          // Keg info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.sports_bar,
                        color: BeerColors.primaryAmber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.beerName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(session.volumeTotalMl / 1000).toStringAsFixed(0)} l · '
                    '${session.alcoholPercent}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    session.status.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Visibility
          Text(
            'Visibility settings',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Show my stats'),
            secondary: const Icon(Icons.lock_open),
            value: _showStats,
            onChanged: (val) => setState(() => _showStats = val),
            tileColor: BeerColors.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Show BAC estimate'),
            secondary: const Icon(Icons.lock_open),
            value: _showBac,
            onChanged: (val) => setState(() => _showBac = val),
            tileColor: BeerColors.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Merge with existing guest
          if (manualUsers.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Are you one of these guests?',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Select yourself to take over their pours, or skip.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final guest in manualUsers)
                  ChoiceChip(
                    label: Text(guest.nickname),
                    selected: _mergeWithManualUserId == guest.id,
                    onSelected: (selected) {
                      setState(() {
                        _mergeWithManualUserId =
                            selected ? guest.id : null;
                      });
                    },
                    selectedColor: BeerColors.primaryAmber,
                    labelStyle: TextStyle(
                      color: _mergeWithManualUserId == guest.id
                          ? BeerColors.background
                          : null,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _isJoining ? null : _join,
            icon: const Icon(Icons.sports_bar),
            label: _isJoining
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BeerColors.background,
                    ),
                  )
                : Text(_mergeWithManualUserId != null
                    ? 'Join & Merge'
                    : 'Join Session'),
          ),
        ],
      ),
    );
  }
}
