import 'dart:async';

import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:beerer/screens/keg/joint_account_sheet.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/bac_calculator.dart';
import 'package:beerer/utils/stats_calculator.dart';
import 'package:beerer/utils/time_formatter.dart';
import 'package:beerer/widgets/bac_banner.dart';
import 'package:beerer/widgets/keg_fill_bar.dart';
import 'package:beerer/widgets/pour_button.dart';
import 'package:beerer/widgets/stat_tile.dart';
import 'package:beerer/widgets/volume_picker_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Main keg session detail screen — adapts to keg status.
class KegDetailScreen extends ConsumerWidget {
  const KegDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(watchSessionProvider(sessionId));
    final poursAsync = ref.watch(watchSessionPoursProvider(sessionId));
    final participantIdsAsync =
        ref.watch(watchParticipantIdsProvider(sessionId));

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Session not found')),
          );
        }
        return _KegDetailBody(
          session: session,
          poursAsync: poursAsync,
          participantIdsAsync: participantIdsAsync,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            color: BeerColors.primaryAmber,
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _KegDetailBody extends ConsumerWidget {
  const _KegDetailBody({
    required this.session,
    required this.poursAsync,
    required this.participantIdsAsync,
  });

  final KegSession session;
  final AsyncValue<List<Pour>> poursAsync;
  final AsyncValue<List<String>> participantIdsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCreator = currentUser?.uid == session.creatorId;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: Text(session.beerName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) =>
                _handleAction(context, ref, value),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'info',
                child: Text('Keg Information'),
              ),
              if (session.status == KegStatus.created && isCreator)
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit session'),
                ),
              if (session.status == KegStatus.created && isCreator)
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete session'),
                ),
              if (session.status == KegStatus.active && isCreator)
                const PopupMenuItem(
                  value: 'pause',
                  child: Text('Untap unfinished keg'),
                ),
              if (session.status == KegStatus.paused && isCreator)
                const PopupMenuItem(
                  value: 'resume',
                  child: Text('Tap keg again'),
                ),
              const PopupMenuItem(
                value: 'share',
                child: Text('Share join link'),
              ),
              if (session.status != KegStatus.done &&
                  session.status != KegStatus.created)
                const PopupMenuItem(
                  value: 'done',
                  child: Text('Mark keg as done'),
                ),
            ],
          ),
        ],
      ),
      body: switch (session.status) {
        KegStatus.created => _buildCreatedBody(context, ref),
        KegStatus.active => _ActiveBody(
          session: session,
          poursAsync: poursAsync,
          participantIdsAsync: participantIdsAsync,
          onShowPourSheet: () => _showPourSheet(context, ref),
          onShowPourForSheet: (String userId, String nickname) =>
              _showPourForSheet(context, ref, userId, nickname),
        ),
        KegStatus.paused => _buildPausedBody(context, ref),
        KegStatus.done => _buildDoneBody(context, ref),
      },
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    final repo = ref.read(kegRepositoryProvider);
    switch (action) {
      case 'info':
        context.go('/keg/${session.id}/info');
      case 'edit':
        // TODO: navigate to edit screen
        break;
      case 'delete':
        _confirmDelete(context, repo);
      case 'pause':
        repo.updateStatus(session.id, KegStatus.paused);
      case 'resume':
        repo.tapKeg(session.id);
      case 'done':
        _confirmDone(context, repo);
      case 'share':
        context.go('/keg/${session.id}/share');
    }
  }

  void _confirmDone(BuildContext context, KegRepository repo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark keg as done?'),
        content: const Text(
          'The session will become read-only. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              repo.updateStatus(session.id, KegStatus.done);
              Navigator.pop(ctx);
            },
            child: const Text('Keg Done'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, KegRepository repo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete session?'),
        content: const Text(
          'This will permanently delete the keg session. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BeerColors.error,
            ),
            onPressed: () async {
              await repo.deleteSession(session.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.go('/home');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedBody(BuildContext context, WidgetRef ref) {
    final isCreator =
        FirebaseAuth.instance.currentUser?.uid == session.creatorId;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'SESSION READY',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 16),
                    const Icon(
                      Icons.sports_bar,
                      size: 64,
                      color: BeerColors.primaryAmber,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      session.beerName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(session.volumeTotalMl / 1000).toStringAsFixed(0)} l'
                      '  ·  ${session.alcoholPercent}%'
                      '  ·  ${TimeFormatter.formatCurrency(session.kegPrice)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: BeerColors.onSurfaceSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap the keg to start!',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isCreator)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ref.read(kegRepositoryProvider).tapKeg(session.id);
                  },
                  icon: const Icon(Icons.sports_bar),
                  label: const Text('Tap Keg!'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedBody(BuildContext context, WidgetRef ref) {
    final isCreator =
        FirebaseAuth.instance.currentUser?.uid == session.creatorId;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BeerColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BeerColors.warning),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.pause_circle_outline,
                    size: 64,
                    color: BeerColors.warning,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keg is untapped',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pouring is disabled.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (isCreator)
              FilledButton.icon(
                onPressed: () {
                  ref.read(kegRepositoryProvider).tapKeg(session.id);
                },
                icon: const Icon(Icons.sports_bar),
                label: const Text('Tap Keg Again'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneBody(BuildContext context, WidgetRef ref) {
    final pours = poursAsync.value ?? [];
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid ?? '';
    final isCreator = uid == session.creatorId;
    final totalPouredMl = StatsCalculator.totalPouredMl(pours);
    final myCost = StatsCalculator.userCost(
      pours,
      uid,
      session.kegPrice,
      session.volumeTotalMl,
    );
    final elapsed = session.startTime != null
        ? DateTime.now().difference(session.startTime!)
        : Duration.zero;
    final participantIds = participantIdsAsync.value ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Completion card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  '🎉',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  'KEG EMPTY',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Session complete! ${TimeFormatter.formatDuration(elapsed)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Final stats
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Final stats',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                StatTile(
                  icon: Icons.sports_bar,
                  label: 'Total poured',
                  value: TimeFormatter.formatVolumeMl(totalPouredMl),
                ),
                StatTile(
                  icon: Icons.people,
                  label: 'Participants',
                  value: '${participantIds.length}',
                ),
                StatTile(
                  icon: Icons.euro,
                  label: 'My total',
                  value: TimeFormatter.formatCurrency(myCost),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (isCreator) ...[
          FilledButton(
            onPressed: () =>
                context.go('/keg/${session.id}/settle'),
            child: const Text('Export to Settle Up'),
          ),
        ],
      ],
    );
  }

  void _showPourSheet(BuildContext context, WidgetRef ref) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final volumeMl = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VolumePickerSheet(
        predefinedVolumesMl: session.predefinedVolumesMl,
      ),
    );

    if (volumeMl == null || !context.mounted) return;

    HapticFeedback.mediumImpact();
    final pour = Pour(
      id: '',
      sessionId: session.id,
      userId: uid,
      pouredById: uid,
      volumeMl: volumeMl,
      timestamp: DateTime.now(),
    );
    try {
      final created = await ref.read(kegRepositoryProvider).addPour(pour);
      if (context.mounted) {
        _showPourSnackBar(context, ref, 'Pour logged!', created);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Pour failed: $e')),
          );
      }
    }
  }

  void _showPourForSheet(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
    String targetNickname,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final volumeMl = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VolumePickerSheet(
        predefinedVolumesMl: session.predefinedVolumesMl,
        title: 'Pour for $targetNickname',
      ),
    );

    if (volumeMl == null || !context.mounted) return;

    HapticFeedback.mediumImpact();
    final pour = Pour(
      id: '',
      sessionId: session.id,
      userId: targetUserId,
      pouredById: uid,
      volumeMl: volumeMl,
      timestamp: DateTime.now(),
    );
    try {
      final created = await ref.read(kegRepositoryProvider).addPour(pour);
      if (context.mounted) {
        _showPourSnackBar(
          context,
          ref,
          'Poured for $targetNickname!',
          created,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Pour failed: $e')),
          );
      }
    }
  }

  /// Unified snackbar for pour confirmation with undo support.
  void _showPourSnackBar(
    BuildContext context,
    WidgetRef ref,
    String message,
    Pour createdPour,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref.read(kegRepositoryProvider).undoPour(createdPour);
            },
          ),
        ),
      );
  }
}

/// Active keg body with a 1-second periodic timer for live stat updates.
class _ActiveBody extends ConsumerStatefulWidget {
  const _ActiveBody({
    required this.session,
    required this.poursAsync,
    required this.participantIdsAsync,
    required this.onShowPourSheet,
    required this.onShowPourForSheet,
  });

  final KegSession session;
  final AsyncValue<List<Pour>> poursAsync;
  final AsyncValue<List<String>> participantIdsAsync;
  final VoidCallback onShowPourSheet;
  final void Function(String userId, String nickname) onShowPourForSheet;

  @override
  ConsumerState<_ActiveBody> createState() => _ActiveBodyState();
}

class _ActiveBodyState extends ConsumerState<_ActiveBody> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final pours = widget.poursAsync.value ?? [];
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid ?? '';
    final userPours =
        pours.where((Pour p) => p.userId == uid).toList();
    final fillPercent =
        session.volumeRemainingMl / session.volumeTotalMl;
    final elapsed = session.startTime != null
        ? DateTime.now().difference(session.startTime!)
        : Duration.zero;
    final predictedEmpty =
        StatsCalculator.predictedTimeUntilEmpty(session, pours);
    final myCost = StatsCalculator.userCost(
      pours,
      uid,
      session.kegPrice,
      session.volumeTotalMl,
    );
    final avgRate = StatsCalculator.averageRateMlPerHour(
      userPours,
      elapsed,
    );
    final myConsumedMl = StatsCalculator.userPouredMl(pours, uid);
    final currentBeerDur =
        StatsCalculator.currentBeerDuration(userPours);
    final timeSinceLast =
        StatsCalculator.timeSinceLastPour(userPours);
    final prefs = ref.watch(formatPreferencesProvider);
    final beerPrice = StatsCalculator.pricePerReferenceBeer(
      session.kegPrice,
      session.volumeTotalMl,
      unit: prefs.volumeUnit,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Combined keg level + my stats card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'KEG LEVEL',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    KegFillBar(
                      fillPercent: fillPercent,
                      height: 150,
                      width: 60,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            TimeFormatter.formatVolumeMl(
                              session.volumeRemainingMl,
                              prefs: prefs,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall,
                          ),
                          Text(
                            'remaining',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                          if (predictedEmpty != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '~${TimeFormatter.formatDuration(predictedEmpty)} until empty',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        BeerColors.onSurfaceSecondary,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // My stats
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'My stats',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                if (currentBeerDur != null)
                  StatTile(
                    icon: Icons.sports_bar,
                    label: 'Current beer',
                    value: TimeFormatter.formatTimer(
                      currentBeerDur,
                    ),
                  ),
                if (timeSinceLast != null)
                  StatTile(
                    icon: Icons.timer,
                    label: 'Since last',
                    value: TimeFormatter.formatTimer(
                      timeSinceLast,
                    ),
                  ),
                StatTile(
                  icon: Icons.bar_chart,
                  label: 'Avg rate',
                  value:
                      '${(avgRate / 1000).toStringAsFixed(1)} l/h',
                ),
                StatTile(
                  icon: Icons.local_drink,
                  label: 'My volume',
                  value: TimeFormatter.formatVolumeMl(
                    myConsumedMl,
                    prefs: prefs,
                  ),
                ),
                StatTile(
                  icon: Icons.euro,
                  label: 'My total',
                  value:
                      TimeFormatter.formatCurrency(myCost, prefs: prefs),
                ),
                if (beerPrice != null)
                  StatTile(
                    icon: Icons.sell,
                    label: StatsCalculator.referenceBeerLabel(
                      prefs.volumeUnit,
                    ),
                    value: TimeFormatter.formatCurrency(
                      beerPrice,
                      prefs: prefs,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // BAC estimate (only if user has weight set)
        if (currentUser != null) ...[
          const SizedBox(height: 12),
          _BacSection(
            userPours: userPours,
            session: session,
            userId: uid,
            ref: ref,
          ),
        ],
        const SizedBox(height: 16),
        // Pour button
        PourButton(
          label: 'I got beer',
          onPressed: widget.onShowPourSheet,
        ),
        const SizedBox(height: 16),
        // Participants
        _ParticipantsSection(
          participantIdsAsync: widget.participantIdsAsync,
          session: session,
          pours: pours,
          ref: ref,
          onPourFor: widget.onShowPourForSheet,
        ),
        const SizedBox(height: 16),
        // Joint Accounts
        _AccountsSection(
          session: session,
          pours: pours,
          participantIds: widget.participantIdsAsync.value ?? [],
          ref: ref,
        ),
      ],
    );
  }
}

/// BAC section — calculates BAC on device only.
class _BacSection extends StatelessWidget {
  const _BacSection({
    required this.userPours,
    required this.session,
    required this.userId,
    required this.ref,
  });

  final List<Pour> userPours;
  final KegSession session;
  final String userId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(watchCurrentUserProvider(userId));
    return userAsync.when(
      data: (user) {
        if (user == null || user.weightKg <= 0) {
          return const SizedBox.shrink();
        }
        final totalAlcGrams = userPours.fold(0.0, (sum, p) {
          return sum +
              BacCalculator.pureAlcoholGrams(
                volumeMl: p.volumeMl,
                abv: session.alcoholPercent,
              );
        });
        final elapsed = session.startTime != null
            ? DateTime.now()
                .difference(session.startTime!)
                .inMinutes
            : 0;
        final bac = BacCalculator.calculate(
          totalAlcoholGrams: totalAlcGrams,
          weightKg: user.weightKg,
          gender: user.gender,
          elapsedMinutes: elapsed,
        );
        return BacBanner(bacValue: bac);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, st) => const SizedBox.shrink(),
    );
  }
}

/// Participants list with per-user stats and pour-for action.
class _ParticipantsSection extends StatelessWidget {
  const _ParticipantsSection({
    required this.participantIdsAsync,
    required this.session,
    required this.pours,
    required this.ref,
    required this.onPourFor,
  });

  final AsyncValue<List<String>> participantIdsAsync;
  final KegSession session;
  final List<Pour> pours;
  final WidgetRef ref;
  final void Function(String userId, String nickname) onPourFor;

  @override
  Widget build(BuildContext context) {
    final ids = participantIdsAsync.value ?? [];
    if (ids.isEmpty) return const SizedBox.shrink();

    final usersAsync = ref.watch(watchUsersProvider(ids));
    final accountsAsync =
        ref.watch(watchSessionAccountsProvider(session.id));
    final accounts = accountsAsync.asData?.value ?? [];

    // Build a userId → groupName lookup.
    final Map<String, String> userGroupNames = {};
    for (final a in accounts) {
      for (final uid in a.memberUserIds) {
        userGroupNames[uid] = a.groupName;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participants',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: BeerColors.onSurfaceSecondary,
              ),
        ),
        const SizedBox(height: 8),
        usersAsync.when(
          data: (users) => Column(
            children: [
              for (final user in users)
                _ParticipantRow(
                  user: user,
                  pours: pours,
                  session: session,
                  ref: ref,
                  groupName: userGroupNames[user.id],
                  onPourFor: () {
                    if (!user.allowPourForMe) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              '${user.displayName} has disabled '
                              '"Pour for me".',
                            ),
                          ),
                        );
                      return;
                    }
                    onPourFor(user.id, user.displayName);
                  },
                ),
            ],
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}

/// A single participant row showing name, beer count, last pour time,
/// estimated BAC, group badge, and a pour-for button.
class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.user,
    required this.pours,
    required this.session,
    required this.ref,
    required this.onPourFor,
    this.groupName,
  });

  final AppUser user;
  final List<Pour> pours;
  final KegSession session;
  final WidgetRef ref;
  final VoidCallback onPourFor;
  final String? groupName;

  @override
  Widget build(BuildContext context) {
    final userPours =
        pours.where((p) => p.userId == user.id && !p.undone).toList();
    final beerCount = userPours.length;
    final lastPourTime = StatsCalculator.timeSinceLastPour(userPours);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = user.id == currentUid;

    // BAC — only if the user has opted in and has weight set
    final showBac =
        (user.preferences['show_bac'] as bool? ?? false) &&
        user.weightKg > 0;
    double? bac;
    if (showBac && session.startTime != null) {
      final totalAlcGrams = userPours.fold(0.0, (sum, p) {
        return sum +
            BacCalculator.pureAlcoholGrams(
              volumeMl: p.volumeMl,
              abv: session.alcoholPercent,
            );
      });
      final elapsed =
          DateTime.now().difference(session.startTime!).inMinutes;
      bac = BacCalculator.calculate(
        totalAlcoholGrams: totalAlcGrams,
        weightKg: user.weightKg,
        gender: user.gender,
        elapsedMinutes: elapsed,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: isMe
                  ? BeerColors.primaryAmber
                  : BeerColors.surfaceVariant,
              child: Text(
                user.displayName[0].toUpperCase(),
                style: TextStyle(
                  color: isMe
                      ? BeerColors.background
                      : BeerColors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName + (isMe ? ' (you)' : ''),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (groupName != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: BeerColors.primaryAmber
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            groupName!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: BeerColors.primaryAmber,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '🍺 $beerCount',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      if (lastPourTime != null)
                        Text(
                          '⏱ ${TimeFormatter.formatDuration(lastPourTime)} ago',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (bac != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '🧪 ${bac.toStringAsFixed(2)} ‰',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Pour-for button (not shown for self)
            if (!isMe)
              IconButton(
                icon: const Icon(
                  Icons.sports_bar,
                  color: BeerColors.primaryAmber,
                ),
                tooltip: 'Pour for ${user.displayName}',
                onPressed: onPourFor,
              ),
          ],
        ),
      ),
    );
  }
}

/// Accounts / bills section showing joint account summaries and a
/// create / join action.
class _AccountsSection extends StatelessWidget {
  const _AccountsSection({
    required this.session,
    required this.pours,
    required this.participantIds,
    required this.ref,
  });

  final KegSession session;
  final List<Pour> pours;
  final List<String> participantIds;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final accountsAsync =
        ref.watch(watchSessionAccountsProvider(session.id));
    final accounts = accountsAsync.asData?.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accounts / Bills',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: BeerColors.onSurfaceSecondary,
              ),
        ),
        const SizedBox(height: 8),
        if (accounts.isNotEmpty)
          for (final account in accounts)
            _AccountCard(
              account: account,
              session: session,
              pours: pours,
            ),
        // Solo participants (not in any group)
        Builder(
          builder: (_) {
            final groupedIds = <String>{};
            for (final a in accounts) {
              groupedIds.addAll(a.memberUserIds);
            }
            final soloIds = participantIds
                .where((id) => !groupedIds.contains(id))
                .toList();
            if (soloIds.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                for (final uid in soloIds)
                  _SoloAccountCard(
                    userId: uid,
                    session: session,
                    pours: pours,
                    ref: ref,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => JointAccountSheet(
                  sessionId: session.id,
                  participantIds: participantIds,
                ),
              );
            },
            icon: const Icon(Icons.group_add, size: 18),
            label: const Text('Join / Create Account'),
          ),
        ),
      ],
    );
  }
}

/// Card showing a joint account's name, member count, total volume, and cost.
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.session,
    required this.pours,
  });

  final JointAccount account;
  final KegSession session;
  final List<Pour> pours;

  @override
  Widget build(BuildContext context) {
    final totalVolumeMl = account.memberUserIds.fold(
      0.0,
      (double sum, String uid) =>
          sum + StatsCalculator.userPouredMl(pours, uid),
    );
    final totalCost = StatsCalculator.groupCost(
      pours,
      account.memberUserIds,
      session.kegPrice,
      session.volumeTotalMl,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.group, color: BeerColors.primaryAmber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.groupName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${account.memberUserIds.length} members · '
                    '${TimeFormatter.formatVolumeMl(totalVolumeMl)} · '
                    '${TimeFormatter.formatCurrency(totalCost)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for a solo participant (not in any joint account).
class _SoloAccountCard extends StatelessWidget {
  const _SoloAccountCard({
    required this.userId,
    required this.session,
    required this.pours,
    required this.ref,
  });

  final String userId;
  final KegSession session;
  final List<Pour> pours;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(watchCurrentUserProvider(userId));
    final volumeMl = StatsCalculator.userPouredMl(pours, userId);
    final cost = StatsCalculator.userCost(
      pours,
      userId,
      session.kegPrice,
      session.volumeTotalMl,
    );

    final displayName = userAsync.asData?.value?.displayName ?? userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.person,
              color: BeerColors.onSurfaceSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$displayName (solo)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${TimeFormatter.formatVolumeMl(volumeMl)} · '
                    '${TimeFormatter.formatCurrency(cost)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
