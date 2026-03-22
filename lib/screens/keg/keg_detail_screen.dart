import 'dart:async';

import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:beerer/screens/keg/joint_account_sheet.dart';
import 'package:beerer/screens/keg/participant_detail_screen.dart';
import 'package:beerer/services/notification_service.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/bac_calculator.dart';
import 'package:beerer/utils/format_preferences.dart';
import 'package:beerer/utils/stats_calculator.dart';
import 'package:beerer/utils/time_formatter.dart';
import 'package:beerer/widgets/avatar_icon.dart';
import 'package:beerer/widgets/keg_fill_bar.dart';
import 'package:beerer/widgets/pour_button.dart';
import 'package:beerer/widgets/stat_tile.dart';
import 'package:beerer/widgets/volume_picker_sheet.dart';
import 'package:beerer/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
            body: Center(child: Text(AppLocalizations.of(context)!.sessionNotFound)),
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
        body: Center(child: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))),
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
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(session.beerName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) =>
                _handleAction(context, ref, value),
            itemBuilder: (ctx) {
              final l10n = AppLocalizations.of(ctx)!;
              return [
              PopupMenuItem(
                value: 'info',
                child: Text(l10n.kegInformation),
              ),
              PopupMenuItem(
                value: 'share',
                child: Text(l10n.shareJoinLink),
              ),
              if (session.status == KegStatus.created && isCreator)
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.editSession),
                ),
              if (session.status == KegStatus.active)
                PopupMenuItem(
                  value: 'pause',
                  child: Text(l10n.untapUnfinishedKeg),
                ),
              if (session.status == KegStatus.paused)
                PopupMenuItem(
                  value: 'resume',
                  child: Text(l10n.tapKegAgain),
                ),
              if (session.status != KegStatus.done &&
                  session.status != KegStatus.created)
                PopupMenuItem(
                  value: 'done',
                  child: Text(l10n.markKegAsDone),
                ),
              if (session.status == KegStatus.created && isCreator)
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l10n.deleteSessionQuestion),
                ),
            ];
            },
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
        context.push('/keg/${session.id}/info');
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
        context.push('/keg/${session.id}/share');
    }
  }

  void _confirmDone(BuildContext context, KegRepository repo) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
        title: Text(l10n.markKegAsDoneQuestion),
        content: Text(l10n.sessionReadOnlyWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              repo.updateStatus(session.id, KegStatus.done);
              Navigator.pop(ctx);
            },
            child: Text(l10n.kegDone),
          ),
        ],
      );
      },
    );
  }

  void _confirmDelete(BuildContext context, KegRepository repo) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
        title: Text(l10n.deleteSessionQuestion),
        content: Text(l10n.deleteSessionWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
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
            child: Text(l10n.delete),
          ),
        ],
      );
      },
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
                      AppLocalizations.of(context)!.sessionReady,
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
                      '${TimeFormatter.formatVolumeMl(session.volumeTotalMl)}'
                      '  ·  ${session.alcoholPercent}%'
                      '  ·  ${TimeFormatter.formatCurrency(session.kegPrice)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: BeerColors.onSurfaceSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.tapTheKegToStart,
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
                  label: Text(AppLocalizations.of(context)!.tapKeg),
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
                    AppLocalizations.of(context)!.kegIsUntapped,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.pouringDisabled,
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
                label: Text(AppLocalizations.of(context)!.tapKegAgain),
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
    final myCost = StatsCalculator.userCostByConsumption(
      pours,
      uid,
      session.kegPrice,
    );
    final elapsed = session.startTime != null
        ? DateTime.now().difference(session.startTime!)
        : Duration.zero;
    final participantIds = participantIdsAsync.value ?? [];
    final prefs = ref.watch(formatPreferencesProvider);

    // Watch participant profiles
    final usersAsync =
        ref.watch(watchUsersProvider(participantIds));
    final users = usersAsync.asData?.value ?? [];

    // Watch joint accounts
    final accountsAsync =
        ref.watch(watchSessionAccountsProvider(session.id));
    final accounts = accountsAsync.asData?.value ?? [];

    // Build userId → account lookup
    final userAccountMap = <String, JointAccount>{};
    for (final a in accounts) {
      for (final memberId in a.memberUserIds) {
        userAccountMap[memberId] = a;
      }
    }

    // Solo users (not in any group)
    final soloUsers =
        users.where((u) => !userAccountMap.containsKey(u.id)).toList();

    return ListView(
      key: const PageStorageKey('done_body_list'),
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
                  AppLocalizations.of(context)!.sessionComplete,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Final stats summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.finalStats,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                StatTile(
                  icon: Icons.timer,
                  label: AppLocalizations.of(context)!.totalKegTime,
                  value: TimeFormatter.formatDuration(elapsed),
                ),
                StatTile(
                  icon: Icons.sports_bar,
                  label: AppLocalizations.of(context)!.totalPoured,
                  value: TimeFormatter.formatVolumeMl(
                    totalPouredMl,
                    prefs: prefs,
                  ),
                ),
                StatTile(
                  icon: Icons.science,
                  label: AppLocalizations.of(context)!.pureAlcohol,
                  value:
                      '${prefs.formatDecimal(StatsCalculator.pureAlcoholMl(pours, session.alcoholPercent), 0)} ml',
                ),
                StatTile(
                  icon: Icons.people,
                  label: AppLocalizations.of(context)!.participantsLabel,
                  value: '${participantIds.length}',
                ),
                StatTile(
                  icon: Icons.euro,
                  label: AppLocalizations.of(context)!.myTotal,
                  value: TimeFormatter.formatCurrency(
                    myCost,
                    prefs: prefs,
                  ),
                ),
                StatTile(
                  icon: Icons.attach_money,
                  label: AppLocalizations.of(context)!.kegPriceLabel2,
                  value: TimeFormatter.formatCurrency(
                    session.kegPrice,
                    prefs: prefs,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Per-participant breakdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.billSplit,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.basedOnActualConsumption,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BeerColors.onSurfaceSecondary,
                      ),
                ),
                const Divider(height: 20),
                // Group accounts first
                for (final account in accounts) ...[
                  _DoneGroupRow(
                    account: account,
                    pours: pours,
                    users: users,
                    kegPrice: session.kegPrice,
                    prefs: prefs,
                  ),
                  const SizedBox(height: 4),
                ],
                // Solo users
                for (final user in soloUsers)
                  _DoneParticipantRow(
                    user: user,
                    pours: pours,
                    kegPrice: session.kegPrice,
                    isMe: user.id == uid,
                    prefs: prefs,
                    session: session,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ParticipantDetailScreen(
                            user: user,
                            session: session,
                            pours: pours,
                            isMe: user.id == uid,
                            prefs: prefs,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (isCreator) ...[
          FilledButton.icon(
            onPressed: () =>
                context.push('/keg/${session.id}/review'),
            icon: const Icon(Icons.edit_note),
            label: Text(AppLocalizations.of(context)!.reviewBill),
          ),
          // Step 14: Settle Up export disabled — keep code, hide UI.
          // if (false)
          //   FilledButton(
          //     onPressed: () =>
          //         context.go('/keg/${session.id}/settle'),
          //     child: const Text('Export to Settle Up'),
          //   ),
          const SizedBox(height: 12),
        ],
        // Tip the developer
        Card(
          color: BeerColors.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  '🍻',
                  style: TextStyle(fontSize: 36),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.enjoyUsingBeerer,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.buyDeveloperBeer,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BeerColors.onSurfaceSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://revolut.me/hnyko'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.favorite, size: 18),
                  label: Text(AppLocalizations.of(context)!.tipViaRevolut),
                ),
              ],
            ),
          ),
        ),
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
        _showPourSnackBar(context, ref, AppLocalizations.of(context)!.pourLogged, created);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.pourFailed(e.toString()))),
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
        title: AppLocalizations.of(context)!.pourForNickname(targetNickname),
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
          AppLocalizations.of(context)!.pouredForNickname(targetNickname),
          created,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.pourFailed(e.toString()))),
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
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.undo,
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

  /// Tracks the last BAC-zero duration we scheduled (in whole minutes)
  /// so we avoid re-scheduling every second rebuild.
  int? _lastScheduledMinutes;

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

  /// Schedule or cancel the BAC-zero local notification.
  void _syncBacZeroNotification(double bac, bool enabled) {
    if (!enabled || bac <= 0) {
      if (_lastScheduledMinutes != null) {
        NotificationService.instance.cancelBacZeroNotification();
        _lastScheduledMinutes = null;
      }
      return;
    }
    final timeToZero = BacCalculator.timeToZero(bac);
    final minutes = timeToZero?.inMinutes;
    if (minutes == _lastScheduledMinutes) return; // no meaningful change
    _lastScheduledMinutes = minutes;
    NotificationService.instance.scheduleBacZeroNotification(timeToZero);
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
        StatsCalculator.timeSinceLastPour(userPours);
    final timeSinceLast =
        StatsCalculator.timeSinceLastPour(userPours);
    final prefs = ref.watch(formatPreferencesProvider);
    final beerPrice = StatsCalculator.pricePerReferenceBeer(
      session.kegPrice,
      session.volumeTotalMl,
      unit: prefs.volumeUnit,
    );

    // BAC for My Stats — compute if user has weight set
    final appUserAsync = ref.watch(watchCurrentUserProvider(uid));
    final appUser = appUserAsync.asData?.value;
    double? myBac;
    if (appUser != null &&
        appUser.weightKg > 0 &&
        session.startTime != null) {
      myBac = BacCalculator.estimateFromPours(
        pours: userPours,
        abv: session.alcoholPercent,
        weightKg: appUser.weightKg,
        gender: appUser.gender,
        elapsedMinutes: elapsed.inMinutes,
      );
    }

    // Slowdown detection — show/cancel local notification based on pref.
    final notifySlowdown =
        appUser?.preferences['notify_slowdown'] as bool? ?? true;
    if (notifySlowdown && StatsCalculator.isSlowingDown(userPours)) {
      NotificationService.instance.showSlowdownNotification();
    } else {
      NotificationService.instance.cancelSlowdownNotification();
    }

    // Alcohol volume helpers for display
    final alcoholDrunkMl = StatsCalculator.pureAlcoholMl(
      pours,
      session.alcoholPercent,
    );
    final alcoholRemainingMl = StatsCalculator.pureAlcoholRemainingMl(
      session.volumeRemainingMl,
      session.alcoholPercent,
    );
    final myAlcoholMl = StatsCalculator.userPureAlcoholMl(
      pours,
      uid,
      session.alcoholPercent,
    );
    final myBeerCount = StatsCalculator.beerCount(pours, uid);

    // BAC — compute timeToZero for drive time
    Duration? timeToZeroDur;
    if (myBac != null && myBac > 0) {
      timeToZeroDur = BacCalculator.timeToZero(myBac);
    }

    // Schedule / cancel BAC-zero notification.
    final notifyBacZero =
        appUser?.preferences['notify_bac_zero'] as bool? ?? true;
    _syncBacZeroNotification(myBac ?? 0, notifyBacZero);

    return ListView(
      key: const PageStorageKey('active_body_list'),
      padding: const EdgeInsets.all(16),
      children: [
        // Combined keg level + my stats card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header row: KEG LEVEL + 0.5l price
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.kegLevel,
                        style:
                            Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    if (beerPrice != null)
                      Text(
                        '${StatsCalculator.referenceBeerLabel(prefs.volumeUnit)}: '
                        '${TimeFormatter.formatCurrency(beerPrice, prefs: prefs)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: BeerColors.onSurfaceSecondary,
                            ),
                      ),
                  ],
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
                            AppLocalizations.of(context)!.remaining,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                          const SizedBox(height: 8),
                          // Alcohol volume drunk / remaining
                          Text(
                            '🧪 ${prefs.formatDecimal(alcoholDrunkMl, 0)} ml / '
                            '${prefs.formatDecimal(alcoholRemainingMl, 0)} ml alc.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      BeerColors.onSurfaceSecondary,
                                ),
                          ),
                          if (predictedEmpty != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '~${TimeFormatter.formatDuration(predictedEmpty)} ${AppLocalizations.of(context)!.untilEmpty}',
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
                    AppLocalizations.of(context)!.myStats,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                if (currentBeerDur != null)
                  StatTile(
                    icon: Icons.sports_bar,
                    label: AppLocalizations.of(context)!.currentBeer,
                    value: TimeFormatter.formatTimer(
                      currentBeerDur,
                    ),
                  ),
                if (timeSinceLast != null)
                  StatTile(
                    icon: Icons.timer,
                    label: AppLocalizations.of(context)!.sinceLast,
                    value: TimeFormatter.formatTimer(
                      timeSinceLast,
                    ),
                  ),
                StatTile(
                  icon: Icons.bar_chart,
                  label: AppLocalizations.of(context)!.avgRate,
                  value:
                      '${prefs.formatDecimal(avgRate / 1000, 1)} l/h',
                ),
                StatTile(
                  icon: Icons.local_drink,
                  label: AppLocalizations.of(context)!.myVolume,
                  value: TimeFormatter.formatVolumeMl(
                    myConsumedMl,
                    prefs: prefs,
                  ),
                ),
                StatTile(
                  icon: Icons.science,
                  label: AppLocalizations.of(context)!.pureAlcohol,
                  value: '${prefs.formatDecimal(myAlcoholMl, 1)} ml',
                ),
                StatTile(
                  icon: Icons.euro,
                  label: AppLocalizations.of(context)!.myTotal,
                  value:
                      TimeFormatter.formatCurrency(myCost, prefs: prefs),
                ),
                StatTile(
                  icon: Icons.sports_bar_outlined,
                  label: AppLocalizations.of(context)!.beers,
                  value: prefs.formatDecimal(myBeerCount, 1),
                ),
                if (myBac != null && myBac > 0) ...[
                  StatTile(
                    icon: Icons.science,
                    label: AppLocalizations.of(context)!.bacEstimate,
                    value: '${prefs.formatDecimal(myBac, 2)} ‰',
                  ),
                  if (timeToZeroDur != null)
                    StatTile(
                      icon: Icons.directions_car,
                      label: AppLocalizations.of(context)!.driveIn,
                      value:
                          '~${TimeFormatter.formatDuration(timeToZeroDur)}',
                    ),
                ],
                if (myBac != null && myBac > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      AppLocalizations.of(context)!.bacEstimateWarning,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: BeerColors.warning,
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Pour button
        PourButton(
          label: AppLocalizations.of(context)!.iGotBeer,
          onPressed: widget.onShowPourSheet,
        ),
        const SizedBox(height: 16),
        // Participants
        _ParticipantsSection(
          participantIdsAsync: widget.participantIdsAsync,
          session: session,
          pours: pours,
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

/// Participants list with per-user stats and pour-for action.
class _ParticipantsSection extends ConsumerWidget {
  const _ParticipantsSection({
    required this.participantIdsAsync,
    required this.session,
    required this.pours,
    required this.onPourFor,
  });

  final AsyncValue<List<String>> participantIdsAsync;
  final KegSession session;
  final List<Pour> pours;
  final void Function(String userId, String nickname) onPourFor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = participantIdsAsync.value ?? [];
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = currentUid == session.creatorId;

    final usersAsync = ref.watch(watchUsersProvider(ids));
    final accountsAsync =
        ref.watch(watchSessionAccountsProvider(session.id));
    final accounts = accountsAsync.asData?.value ?? [];
    final manualUsersAsync =
        ref.watch(watchManualUsersProvider(session.id));
    final manualUsers = manualUsersAsync.asData?.value ?? [];

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
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.participantsLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: BeerColors.onSurfaceSecondary,
                    ),
              ),
            ),
            if (isCreator &&
                session.status != KegStatus.done)
              TextButton.icon(
                onPressed: () => _showAddGuestDialog(context, ref),
                icon: const Icon(Icons.person_add, size: 18),
                label: Text(AppLocalizations.of(context)!.addGuest),
              ),
          ],
        ),
        const SizedBox(height: 8),
        usersAsync.when(
          skipLoadingOnReload: true,
          data: (users) {
            final prefs = ref.watch(formatPreferencesProvider);
            final currentUid = FirebaseAuth.instance.currentUser?.uid;
            return Column(
            children: [
              for (final user in users)
                _ParticipantRow(
                  user: user,
                  pours: pours,
                  session: session,
                  ref: ref,
                  groupName: userGroupNames[user.id],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ParticipantDetailScreen(
                          user: user,
                          session: session,
                          pours: pours,
                          isMe: user.id == currentUid,
                          prefs: prefs,
                        ),
                      ),
                    );
                  },
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
              // Manual (guest) users
              for (final guest in manualUsers)
                _ManualParticipantRow(
                  guest: guest,
                  pours: pours,
                  session: session,
                  isCreator: isCreator,
                  onPourFor: () =>
                      onPourFor(guest.id, guest.nickname),
                  onRemove: () => _removeGuest(context, ref, guest),
                ),
            ],
          );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())),
        ),
      ],
    );
  }

  Future<void> _showAddGuestDialog(
      BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addGuest),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.guestName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    final repo = ref.read(kegRepositoryProvider);
    await repo.addManualUser(session.id, name);
  }

  Future<void> _removeGuest(
      BuildContext context, WidgetRef ref, ManualUser guest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeGuest),
        content: Text(
          AppLocalizations.of(context)!.removeGuestConfirm(guest.nickname),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = ref.read(kegRepositoryProvider);
    await repo.removeManualUser(session.id, guest.id);
  }
}

/// A row for a manual (guest) participant.
class _ManualParticipantRow extends StatelessWidget {
  const _ManualParticipantRow({
    required this.guest,
    required this.pours,
    required this.session,
    required this.isCreator,
    required this.onPourFor,
    required this.onRemove,
  });

  final ManualUser guest;
  final List<Pour> pours;
  final KegSession session;
  final bool isCreator;
  final VoidCallback onPourFor;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final guestPours =
        pours.where((p) => p.userId == guest.id && !p.undone).toList();
    final beerCountVal = StatsCalculator.beerCount(pours, guest.id);
    final lastPourTime = StatsCalculator.timeSinceLastPour(guestPours);
    final guestCost = StatsCalculator.userCost(
      pours,
      guest.id,
      session.kegPrice,
      session.volumeTotalMl,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar
            AvatarCircle(
              displayName: guest.nickname,
              radius: 18,
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
                          guest.nickname,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.guestLower,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '🍺 ${TimeFormatter.formatBeerCount(beerCountVal)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '💰 ${TimeFormatter.formatCurrency(guestCost)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (lastPourTime != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '⏱ ${TimeFormatter.formatDuration(lastPourTime)} ${AppLocalizations.of(context)!.ago}',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Pour-for button
            if (session.status == KegStatus.active)
              IconButton(
                icon: const Icon(
                  Icons.sports_bar,
                  color: BeerColors.primaryAmber,
                ),
                tooltip: AppLocalizations.of(context)!.pourForNickname(guest.nickname),
                onPressed: onPourFor,
              ),
            // Remove button (creator only)
            if (isCreator)
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                tooltip: AppLocalizations.of(context)!.removeGuestTooltip,
                onPressed: onRemove,
              ),
          ],
        ),
      ),
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
    this.onTap,
  });

  final AppUser user;
  final List<Pour> pours;
  final KegSession session;
  final WidgetRef ref;
  final VoidCallback onPourFor;
  final String? groupName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final userPours =
        pours.where((p) => p.userId == user.id && !p.undone).toList();
    final beerCountVal = StatsCalculator.beerCount(pours, user.id);
    final lastPourTime = StatsCalculator.timeSinceLastPour(userPours);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = user.id == currentUid;
    final userCost = StatsCalculator.userCost(
      pours,
      user.id,
      session.kegPrice,
      session.volumeTotalMl,
    );

    // BAC — only if the user has opted in and has weight set
    final showBac =
        (user.preferences['show_bac'] as bool? ?? false) &&
        user.weightKg > 0;
    double? bac;
    if (showBac && session.startTime != null) {
      final elapsed =
          DateTime.now().difference(session.startTime!).inMinutes;
      bac = BacCalculator.estimateFromPours(
        pours: userPours,
        abv: session.alcoholPercent,
        weightKg: user.weightKg,
        gender: user.gender,
        elapsedMinutes: elapsed,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Avatar
              AvatarCircle(
                displayName: user.displayName,
                avatarIcon: user.avatarIcon,
                radius: 18,
                isHighlighted: isMe,
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
                          user.displayName + (isMe ? AppLocalizations.of(context)!.youSuffix : ''),
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
                        '🍺 ${TimeFormatter.formatBeerCount(beerCountVal)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '💰 ${TimeFormatter.formatCurrency(userCost)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (lastPourTime != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '⏱ ${TimeFormatter.formatDuration(lastPourTime)} ${AppLocalizations.of(context)!.ago}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (bac != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '🧪 ${TimeFormatter.formatBac(bac)}',
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
                tooltip: AppLocalizations.of(context)!.pourForNickname(user.displayName),
                onPressed: onPourFor,
              ),
          ],
          ),
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
          AppLocalizations.of(context)!.accountsBills,
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
            label: Text(AppLocalizations.of(context)!.joinCreateAccount),
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
    final totalVolumeMl = StatsCalculator.groupPouredMl(
      pours,
      account.memberUserIds,
    );
    final totalCost = StatsCalculator.groupCost(
      pours,
      account.memberUserIds,
      session.kegPrice,
      session.volumeTotalMl,
    );
    // Total beer count for the group
    final groupBeerCount = account.memberUserIds.fold(
      0.0,
      (double sum, String uid) =>
          sum + StatsCalculator.beerCount(pours, uid),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            GroupAvatarCircle(
              avatarIcon: account.avatarIcon,
              radius: 18,
            ),
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
                    '${AppLocalizations.of(context)!.membersCount(account.memberUserIds.length)} · '
                    '🍺 ${TimeFormatter.formatBeerCount(groupBeerCount)} · '
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
                    '$displayName (${AppLocalizations.of(context)!.solo})',
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

// ---------------------------------------------------------------
// Done-screen bill-split widgets
// ---------------------------------------------------------------

/// A row showing a single participant's consumption, ratio, and cost
/// on the "done" screen.
class _DoneParticipantRow extends StatelessWidget {
  const _DoneParticipantRow({
    required this.user,
    required this.pours,
    required this.kegPrice,
    required this.isMe,
    required this.prefs,
    required this.session,
    this.onTap,
  });

  final AppUser user;
  final List<Pour> pours;
  final double kegPrice;
  final bool isMe;
  final FormatPreferences prefs;
  final KegSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final volumeMl = StatsCalculator.userPouredMl(pours, user.id);
    final ratio = StatsCalculator.userConsumptionRatio(pours, user.id);
    final cost =
        StatsCalculator.userCostByConsumption(pours, user.id, kegPrice);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AvatarCircle(
              displayName: user.displayName,
              avatarIcon: user.avatarIcon,
              radius: 16,
              isHighlighted: isMe,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName + (isMe ? AppLocalizations.of(context)!.youSuffix : ''),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${TimeFormatter.formatVolumeMl(volumeMl, prefs: prefs)} · '
                    '${TimeFormatter.formatRatio(ratio)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: BeerColors.onSurfaceSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              TimeFormatter.formatCurrency(cost, prefs: prefs),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card showing a joint account group's total on the "done" screen,
/// with each member listed underneath.
class _DoneGroupRow extends StatelessWidget {
  const _DoneGroupRow({
    required this.account,
    required this.pours,
    required this.users,
    required this.kegPrice,
    required this.prefs,
  });

  final JointAccount account;
  final List<Pour> pours;
  final List<AppUser> users;
  final double kegPrice;
  final FormatPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final groupCost = StatsCalculator.groupCostByConsumption(
      pours,
      account.memberUserIds,
      kegPrice,
    );
    final groupVolumeMl = StatsCalculator.groupPouredMl(
      pours,
      account.memberUserIds,
    );
    final groupRatio = StatsCalculator.groupConsumptionRatio(
      pours,
      account.memberUserIds,
    );

    // Resolve member AppUser objects
    final memberUsers = account.memberUserIds
        .map((id) => users.where((u) => u.id == id).firstOrNull)
        .whereType<AppUser>()
        .toList();

    return Card(
      color: BeerColors.primaryAmber.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.group,
                  size: 18,
                  color: BeerColors.primaryAmber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    account.groupName,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                ),
                Text(
                  TimeFormatter.formatCurrency(groupCost, prefs: prefs),
                  style:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                '${TimeFormatter.formatVolumeMl(groupVolumeMl, prefs: prefs)} · '
                '${TimeFormatter.formatRatio(groupRatio)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BeerColors.onSurfaceSecondary,
                    ),
              ),
            ),
            if (memberUsers.length > 1) ...[
              const Divider(height: 16),
              for (final member in memberUsers)
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: _DoneMemberRow(
                    user: member,
                    pours: pours,
                    prefs: prefs,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A lightweight row for a group member inside [_DoneGroupRow].
class _DoneMemberRow extends StatelessWidget {
  const _DoneMemberRow({
    required this.user,
    required this.pours,
    required this.prefs,
  });

  final AppUser user;
  final List<Pour> pours;
  final FormatPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final volumeMl = StatsCalculator.userPouredMl(pours, user.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            user.displayName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            TimeFormatter.formatVolumeMl(volumeMl, prefs: prefs),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BeerColors.onSurfaceSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
