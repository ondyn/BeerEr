import 'dart:async';

import 'package:beerer/l10n/app_localizations.dart';
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
import 'package:beerer/widgets/animated_reorderable_column.dart';
import 'package:beerer/widgets/animated_rolling_text.dart';
import 'package:beerer/widgets/avatar_icon.dart';
import 'package:beerer/widgets/keg_fill_bar.dart';
import 'package:beerer/widgets/stat_tile.dart';
import 'package:beerer/widgets/volume_picker_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show listEquals;
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
      skipLoadingOnReload: true,
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

class _KegDetailBody extends ConsumerStatefulWidget {
  const _KegDetailBody({
    required this.session,
    required this.poursAsync,
    required this.participantIdsAsync,
  });

  final KegSession session;
  final AsyncValue<List<Pour>> poursAsync;
  final AsyncValue<List<String>> participantIdsAsync;

  @override
  ConsumerState<_KegDetailBody> createState() => _KegDetailBodyState();
}

class _KegDetailBodyState extends ConsumerState<_KegDetailBody> {
  /// Timer that auto-dismisses the pour snackbar.
  ///
  /// SnackBar's built-in duration timer gets disrupted when the widget tree
  /// is rebuilt by provider changes + a periodic body ticker. We manage the
  /// dismiss timeout ourselves to guarantee the snackbar disappears.
  Timer? _snackBarTimer;

  KegSession get session => widget.session;
  AsyncValue<List<Pour>> get poursAsync => widget.poursAsync;
  AsyncValue<List<String>> get participantIdsAsync =>
      widget.participantIdsAsync;

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                _handleAction(context, value),
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
        KegStatus.created => _buildCreatedBody(context),
        KegStatus.active => _ActiveBody(
          session: session,
          poursAsync: poursAsync,
          participantIdsAsync: participantIdsAsync,
          onShowPourSheet: () => _showPourSheet(context),
          onShowPourForSheet: (String userId, String nickname) =>
              _showPourForSheet(context, userId, nickname),
        ),
        KegStatus.paused => _buildPausedBody(context),
        KegStatus.done => _buildDoneBody(context),
      },
    );
  }

  void _handleAction(BuildContext context, String action) {
    final repo = ref.read(kegRepositoryProvider);
    switch (action) {
      case 'info':
        context.push('/keg/${session.id}/info');
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

  Widget _buildCreatedBody(BuildContext context) {
    final isCreator =
        FirebaseAuth.instance.currentUser?.uid == session.creatorId;
    final prefs = ref.watch(formatPreferencesProvider);

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
                      '${TimeFormatter.formatVolumeMl(session.volumeTotalMl, prefs: prefs)}'
                      '  ·  ${session.alcoholPercent}%'
                      '  ·  ${TimeFormatter.formatCurrency(session.kegPrice, prefs: prefs)}',
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    context.push('/keg/${session.id}/share'),
                icon: const Icon(Icons.qr_code),
                label: Text(AppLocalizations.of(context)!.shareJoinLink),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                  backgroundColor: BeerColors.surfaceVariant,
                  foregroundColor: BeerColors.primaryAmber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedBody(BuildContext context) {
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

  Widget _buildDoneBody(BuildContext context) {
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
                  icon: Icons.attach_money,
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

  void _showPourSheet(BuildContext context) async {
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
        _showPourSnackBar(context, AppLocalizations.of(context)!.pourLogged, created);
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
  ///
  /// Uses a manual [Timer] to dismiss the snackbar instead of relying on
  /// [SnackBar.duration]. The built-in duration timer gets disrupted when
  /// the widget tree is rebuilt by Riverpod provider changes combined with
  /// the periodic 1-second refresh timer in [_ActiveBody], causing the
  /// snackbar to stay visible indefinitely. A manual timer is immune to
  /// widget rebuilds.
  void _showPourSnackBar(
    BuildContext context,
    String message,
    Pour createdPour,
  ) {
    _snackBarTimer?.cancel();
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          // Use a very long duration so the built-in timer never fires;
          // our manual timer below takes care of dismissal.
          duration: const Duration(days: 1),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.undo,
            onPressed: () {
              _snackBarTimer?.cancel();
              ref.read(kegRepositoryProvider).undoPour(createdPour);
            },
          ),
        ),
      );

    _snackBarTimer = Timer(const Duration(seconds: 5), () {
      messenger.hideCurrentSnackBar();
    });
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
  ///
  /// Skips scheduling if the user has not consumed any beer (no pours).
  void _syncBacZeroNotification(double bac, bool enabled, {required bool hasPours}) {
    if (!enabled || bac <= 0 || !hasPours) {
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
    final prefs = ref.watch(formatPreferencesProvider);
    final beerPrice = StatsCalculator.pricePerReferenceBeer(
      session.kegPrice,
      session.volumeTotalMl,
      unit: prefs.volumeUnit,
    );

    // BAC — compute if user has weight set (for notifications)
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

    // Schedule / cancel BAC-zero notification.
    final notifyBacZero =
        appUser?.preferences['notify_bac_zero'] as bool? ?? true;
    _syncBacZeroNotification(
      myBac ?? 0,
      notifyBacZero,
      hasPours: userPours.where((p) => !p.undone).isNotEmpty,
    );

    return ListView(
      key: const PageStorageKey('active_body_list'),
      padding: const EdgeInsets.all(16),
      children: [
        // Keg level detail card — tap to open keg info
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/keg/${session.id}/info'),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Compact keg fill indicator
                  KegFillBar(
                    fillPercent: fillPercent,
                    height: 80,
                    width: 40,
                  ),
                  const SizedBox(width: 14),
                  // Main stats column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Volume remaining + label
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              TimeFormatter.formatVolumeMl(
                                session.volumeRemainingMl,
                                prefs: prefs,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context)!.remaining,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: BeerColors.onSurfaceSecondary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Inline stats row
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _MiniStat(
                              icon: Icons.science,
                              text:
                                  '${prefs.formatDecimal(alcoholDrunkMl, 0)}/${prefs.formatDecimal(alcoholRemainingMl, 0)} ml alc.',
                            ),
                            if (predictedEmpty != null)
                              _MiniStat(
                                icon: Icons.timer_outlined,
                                text:
                                    '~${TimeFormatter.formatDuration(predictedEmpty)} ${AppLocalizations.of(context)!.untilEmpty}',
                              ),
                            if (beerPrice != null)
                              _MiniStat(
                                icon: Icons.attach_money,
                                text:
                                    '${StatsCalculator.referenceBeerLabel(prefs.volumeUnit)}: '
                                    '${TimeFormatter.formatCurrency(beerPrice, prefs: prefs)}',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Chevron hint
                  const Icon(
                    Icons.chevron_right,
                    color: BeerColors.onSurfaceSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Participants list (directly below keg level)
        _ParticipantsSection(
          participantIdsAsync: widget.participantIdsAsync,
          session: session,
          pours: pours,
          onPourFor: widget.onShowPourForSheet,
          onPourSelf: widget.onShowPourSheet,
        ),
        const SizedBox(height: 16),
        // Joint Accounts
        _AccountsSection(
          session: session,
          pours: pours,
          participantIds: widget.participantIdsAsync.value ?? [],
        ),
      ],
    );
  }
}

/// Participants list with per-user stats and pour-for action.
///
/// Must be a [ConsumerStatefulWidget] (not ConsumerWidget) so that the
/// [AnimatedReorderableColumn] and [AnimatedRollingText] child States
/// survive the 1-second timer rebuilds from [_ActiveBodyState].
class _ParticipantsSection extends ConsumerStatefulWidget {
  const _ParticipantsSection({
    required this.participantIdsAsync,
    required this.session,
    required this.pours,
    required this.onPourFor,
    required this.onPourSelf,
  });

  final AsyncValue<List<String>> participantIdsAsync;
  final KegSession session;
  final List<Pour> pours;
  final void Function(String userId, String nickname) onPourFor;
  final VoidCallback onPourSelf;

  @override
  ConsumerState<_ParticipantsSection> createState() =>
      _ParticipantsSectionState();
}

class _ParticipantsSectionState extends ConsumerState<_ParticipantsSection> {
  /// Cached participant IDs list.
  ///
  /// Riverpod family providers use identity-based equality for `List`
  /// parameters. If we pass a new `List<String>` with the same content,
  /// Riverpod creates a **new** provider instance, which starts in the
  /// `loading` state and causes the [AnimatedReorderableColumn] State to
  /// be destroyed and recreated (visible as a flicker).
  ///
  /// We cache the list and only swap it when the content actually changes,
  /// so that `ref.watch(watchUsersProvider(_cachedIds))` always hits the
  /// same provider instance for the same participant set.
  List<String> _cachedIds = const [];

  List<String> _resolveIds() {
    final newIds = widget.participantIdsAsync.value ?? [];
    if (!listEquals(_cachedIds, newIds)) {
      _cachedIds = newIds;
    }
    return _cachedIds;
  }

  @override
  Widget build(BuildContext context) {
    final ids = _resolveIds();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = currentUid == widget.session.creatorId;

    final usersAsync = ref.watch(watchUsersProvider(ids));
    final accountsAsync =
        ref.watch(watchSessionAccountsProvider(widget.session.id));
    final accounts = accountsAsync.asData?.value ?? [];
    final manualUsersAsync =
        ref.watch(watchManualUsersProvider(widget.session.id));
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
        Text(
          AppLocalizations.of(context)!.participantsLabel,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: BeerColors.onSurfaceSecondary,
              ),
        ),
        const SizedBox(height: 8),
        usersAsync.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          data: (users) {
            final prefs = ref.watch(formatPreferencesProvider);
            final currentUid = FirebaseAuth.instance.currentUser?.uid;

            // -- Compute rankings (by volume drunk, descending) ----------
            // Combine registered users + guests into one ranked list.
            final allIds = <String>[
              ...users.map((u) => u.id),
              ...manualUsers.map((g) => g.id),
            ];
            final volumeById = <String, double>{
              for (final id in allIds)
                id: StatsCalculator.userPouredMl(widget.pours, id),
            };
            // Sort ids by volume descending to assign rank.
            final sortedIds = [...allIds]
              ..sort((a, b) => volumeById[b]!.compareTo(volumeById[a]!));
            final rankOf = <String, int>{};
            for (var i = 0; i < sortedIds.length; i++) {
              rankOf[sortedIds[i]] = i + 1;
            }

            // -- Sort users: logged-in user first, then by rank ----------
            final sortedUsers = [...users]..sort((a, b) {
                if (a.id == currentUid) return -1;
                if (b.id == currentUid) return 1;
                return (rankOf[a.id] ?? 99).compareTo(rankOf[b.id] ?? 99);
              });
            final sortedGuests = [...manualUsers]..sort((a, b) {
                return (rankOf[a.id] ?? 99).compareTo(rankOf[b.id] ?? 99);
              });

            // Build a unified ordered key list for the animated column.
            // Current user is always first (pinned at top).
            final orderedKeys = <String>[
              for (final user in sortedUsers) 'participant_${user.id}',
              for (final guest in sortedGuests) 'guest_${guest.id}',
            ];

            // Build lookup maps for quick access by key.
            final userByKey = <String, AppUser>{
              for (final user in sortedUsers) 'participant_${user.id}': user,
            };
            final guestByKey = <String, ManualUser>{
              for (final guest in sortedGuests) 'guest_${guest.id}': guest,
            };

            return AnimatedReorderableColumn(
              itemKeys: orderedKeys,
              itemBuilder: (key) {
                // Registered user row
                if (userByKey.containsKey(key)) {
                  final user = userByKey[key]!;
                  return _UnifiedParticipantRow(
                    key: ValueKey(key),
                    displayName: user.displayName +
                        (user.id == currentUid
                            ? AppLocalizations.of(context)!.youSuffix
                            : ''),
                    avatarIcon: user.avatarIcon,
                    isMe: user.id == currentUid,
                    isGuest: false,
                    rank: rankOf[user.id] ?? 0,
                    beerCount: StatsCalculator.beerCount(widget.pours, user.id),
                    cost: StatsCalculator.userCost(
                      widget.pours, user.id, widget.session.kegPrice, widget.session.volumeTotalMl,
                    ),
                    lastPourTime: StatsCalculator.timeSinceLastPour(
                      widget.pours.where((p) => p.userId == user.id && !p.undone).toList(),
                    ),
                    groupName: userGroupNames[user.id],
                    prefs: prefs,
                    showPourButton: widget.session.status == KegStatus.active,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ParticipantDetailScreen(
                            user: user,
                            session: widget.session,
                            pours: widget.pours,
                            isMe: user.id == currentUid,
                            prefs: prefs,
                          ),
                        ),
                      );
                    },
                    onPour: () {
                      if (user.id == currentUid) {
                        widget.onPourSelf();
                      } else {
                        if (!user.allowPourForMe) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!
                                      .pourForDisabled(user.displayName),
                                ),
                              ),
                            );
                          return;
                        }
                        widget.onPourFor(user.id, user.displayName);
                      }
                    },
                  );
                }
                // Guest row
                final guest = guestByKey[key]!;
                return _UnifiedParticipantRow(
                  key: ValueKey(key),
                  displayName: guest.nickname,
                  isMe: false,
                  isGuest: true,
                  rank: rankOf[guest.id] ?? 0,
                  beerCount: StatsCalculator.beerCount(widget.pours, guest.id),
                  cost: StatsCalculator.userCost(
                    widget.pours, guest.id, widget.session.kegPrice, widget.session.volumeTotalMl,
                  ),
                  lastPourTime: StatsCalculator.timeSinceLastPour(
                    widget.pours.where((p) => p.userId == guest.id && !p.undone).toList(),
                  ),
                  prefs: prefs,
                  showPourButton: widget.session.status == KegStatus.active,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ParticipantDetailScreen(
                          guest: guest,
                          session: widget.session,
                          pours: widget.pours,
                          isMe: false,
                          prefs: prefs,
                          onRemoveGuest: isCreator
                              ? () => _removeGuest(context, ref, guest)
                              : null,
                        ),
                      ),
                    );
                  },
                  onPour: () => widget.onPourFor(guest.id, guest.nickname),
                );
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())),
        ),
      ],
    );
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
    await repo.removeManualUser(widget.session.id, guest.id);

    // Pop the guest detail screen that initiated this action.
    if (context.mounted) Navigator.of(context).pop();
  }
}

/// Unified participant row for both registered users and guests.
///
/// Shows: rank badge, avatar, name, beer count, cost, last pour time,
/// and a prominent pour button.
///
/// Uses [AnimatedRollingText] for beer count, cost, and timer values
/// so that changes animate with a vertical roll effect.
class _UnifiedParticipantRow extends StatelessWidget {
  const _UnifiedParticipantRow({
    super.key,
    required this.displayName,
    required this.isMe,
    required this.isGuest,
    required this.rank,
    required this.beerCount,
    required this.cost,
    required this.prefs,
    required this.showPourButton,
    required this.onTap,
    required this.onPour,
    this.avatarIcon,
    this.lastPourTime,
    this.groupName,
  });

  final String displayName;
  final int? avatarIcon;
  final bool isMe;
  final bool isGuest;
  final int rank;
  final double beerCount;
  final double cost;
  final Duration? lastPourTime;
  final String? groupName;
  final FormatPreferences prefs;
  final bool showPourButton;
  final VoidCallback onTap;
  final VoidCallback onPour;

  @override
  Widget build(BuildContext context) {
    final smallStyle = Theme.of(context).textTheme.bodySmall;

    // Pre-format values for the rolling text animation.
    final beerCountText = prefs.formatDecimal(beerCount, 1);
    final costText = TimeFormatter.formatCurrency(cost, prefs: prefs,
        decimalPlaces: 0);
    final timerText = lastPourTime != null
        ? '${TimeFormatter.formatDuration(lastPourTime!)} ${AppLocalizations.of(context)!.ago}'
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              // Rank badge
              SizedBox(
                width: 22,
                child: AnimatedRollingText(
                  text: '#$rank',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: rank <= 3
                            ? BeerColors.primaryAmber
                            : BeerColors.onSurfaceSecondary,
                        fontWeight:
                            rank <= 3 ? FontWeight.w700 : FontWeight.normal,
                      ),
                ),
              ),
              const SizedBox(width: 4),
              // Avatar
              AvatarCircle(
                displayName: displayName,
                avatarIcon: avatarIcon,
                radius: 20,
                isHighlighted: isMe,
              ),
              const SizedBox(width: 12),
              // Name + info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isGuest) ...[
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.sports_bar_outlined,
                            size: 14, color: BeerColors.onSurfaceSecondary),
                        const SizedBox(width: 3),
                        AnimatedRollingText(
                          text: beerCountText,
                          style: smallStyle,
                        ),
                        const SizedBox(width: 12),
                        AnimatedRollingText(
                          text: costText,
                          style: smallStyle,
                        ),
                        if (timerText != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.timer,
                              size: 13, color: BeerColors.onSurfaceSecondary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              timerText,
                              style: smallStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Pour button — prominent filled icon button
              if (showPourButton)
                FilledButton(
                  onPressed: onPour,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Icon(Icons.sports_bar, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Accounts / bills section showing joint account summaries and a
/// create / join action, plus "Add Guest" for the keg creator.
class _AccountsSection extends ConsumerWidget {
  const _AccountsSection({
    required this.session,
    required this.pours,
    required this.participantIds,
  });

  final KegSession session;
  final List<Pour> pours;
  final List<String> participantIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync =
        ref.watch(watchSessionAccountsProvider(session.id));
    final accounts = accountsAsync.asData?.value ?? [];
    final manualUsersAsync =
        ref.watch(watchManualUsersProvider(session.id));
    final manualUsers = manualUsersAsync.asData?.value ?? [];
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = currentUid == session.creatorId;
    final prefs = ref.watch(formatPreferencesProvider);

    // Collect IDs that are already in a joint account group.
    final groupedIds = <String>{};
    for (final a in accounts) {
      groupedIds.addAll(a.memberUserIds);
    }

    // Solo registered participants (not in any group).
    final soloIds =
        participantIds.where((id) => !groupedIds.contains(id)).toList();

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
        // Joint account groups
        if (accounts.isNotEmpty)
          for (final account in accounts)
            _AccountCard(
              account: account,
              session: session,
              pours: pours,
              prefs: prefs,
            ),
        // Solo registered participants (not in any group)
        if (soloIds.isNotEmpty)
          for (final uid in soloIds)
            _SoloAccountCard(
              userId: uid,
              session: session,
              pours: pours,
              prefs: prefs,
              ref: ref,
            ),
        // Guests (manual users) — always shown as solo entries
        for (final guest in manualUsers)
          _GuestAccountCard(
            guest: guest,
            session: session,
            pours: pours,
            prefs: prefs,
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isCreator && session.status == KegStatus.active)
              TextButton.icon(
                onPressed: () => _showAddGuestDialog(context, ref),
                icon: const Icon(Icons.person_add, size: 18),
                label: Text(AppLocalizations.of(context)!.addPerson),
              ),
            if (isCreator && session.status == KegStatus.active)
              const SizedBox(width: 8),
            TextButton.icon(
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
          ],
        ),
      ],
    );
  }

  void _showAddGuestDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.addGuest),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.nickname,
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                // Validate: no duplicate name among registered users or guests.
                final existingGuestsAsync =
                    ref.read(watchManualUsersProvider(session.id));
                final existingGuests =
                    existingGuestsAsync.asData?.value ?? [];
                final existingUsersAsync =
                    ref.read(watchUsersProvider(participantIds));
                final existingUsers =
                    existingUsersAsync.asData?.value ?? [];

                final lowerName = name.toLowerCase();
                final isDuplicate =
                    existingGuests.any((g) =>
                        g.nickname.toLowerCase() == lowerName) ||
                    existingUsers.any((u) =>
                        u.displayName.toLowerCase() == lowerName);

                if (isDuplicate) {
                  setDialogState(
                    () => errorText =
                        AppLocalizations.of(context)!.guestNameTaken,
                  );
                  return;
                }

                Navigator.pop(ctx);
                final repo = ref.read(kegRepositoryProvider);
                await repo.addManualUser(session.id, name);
              },
              child: Text(AppLocalizations.of(context)!.add),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for a guest (manual user) in the Accounts/Bills section.
class _GuestAccountCard extends StatelessWidget {
  const _GuestAccountCard({
    required this.guest,
    required this.session,
    required this.pours,
    required this.prefs,
  });

  final ManualUser guest;
  final KegSession session;
  final List<Pour> pours;
  final FormatPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final cost = StatsCalculator.userCost(
      pours,
      guest.id,
      session.kegPrice,
      session.volumeTotalMl,
    );
    final beerCount = StatsCalculator.beerCount(pours, guest.id);
    const iconColor = BeerColors.onSurfaceSecondary;
    const iconSize = 14.0;
    final smallStyle = Theme.of(context).textTheme.bodySmall;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            AvatarCircle(
              displayName: guest.nickname,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          guest.nickname,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.sports_bar_outlined,
                          size: iconSize, color: iconColor),
                      const SizedBox(width: 3),
                      Text(prefs.formatDecimal(beerCount, 1),
                          style: smallStyle),
                      const SizedBox(width: 12),
                      Text(
                        TimeFormatter.formatCurrency(cost,
                            prefs: prefs, decimalPlaces: 0),
                        style: smallStyle,
                      ),
                    ],
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

/// Card showing a joint account's name, member count, total volume, and cost.
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.session,
    required this.pours,
    required this.prefs,
  });

  final JointAccount account;
  final KegSession session;
  final List<Pour> pours;
  final FormatPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final totalCost = StatsCalculator.groupCost(
      pours,
      account.memberUserIds,
      session.kegPrice,
      session.volumeTotalMl,
    );
    final groupBeerCount = account.memberUserIds.fold(
      0.0,
      (double sum, String uid) => sum + StatsCalculator.beerCount(pours, uid),
    );
    final smallStyle = Theme.of(context).textTheme.bodySmall;
    const iconColor = BeerColors.onSurfaceSecondary;
    const iconSize = 14.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            GroupAvatarCircle(
              avatarIcon: account.avatarIcon,
              radius: 20,
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
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: iconSize, color: iconColor),
                      const SizedBox(width: 3),
                      Text('${account.memberUserIds.length}', style: smallStyle),
                      const SizedBox(width: 12),
                      const Icon(Icons.sports_bar_outlined,
                          size: iconSize, color: iconColor),
                      const SizedBox(width: 3),
                      Text(prefs.formatDecimal(groupBeerCount, 1),
                          style: smallStyle),
                      const SizedBox(width: 12),
                      Text(
                        TimeFormatter.formatCurrency(totalCost,
                            prefs: prefs, decimalPlaces: 0),
                        style: smallStyle,
                      ),
                    ],
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
    required this.prefs,
    required this.ref,
  });

  final String userId;
  final KegSession session;
  final List<Pour> pours;
  final FormatPreferences prefs;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(watchCurrentUserProvider(userId));
    final cost = StatsCalculator.userCost(
      pours,
      userId,
      session.kegPrice,
      session.volumeTotalMl,
    );
    final beerCount = StatsCalculator.beerCount(pours, userId);
    final user = userAsync.asData?.value;
    final displayName = user?.displayName ?? userId;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = userId == currentUid;
    const iconColor = BeerColors.onSurfaceSecondary;
    const iconSize = 14.0;
    final smallStyle = Theme.of(context).textTheme.bodySmall;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            AvatarCircle(
              displayName: displayName,
              avatarIcon: user?.avatarIcon,
              radius: 20,
              isHighlighted: isMe,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName + (isMe ? AppLocalizations.of(context)!.youSuffix : ''),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.sports_bar_outlined,
                          size: iconSize, color: iconColor),
                      const SizedBox(width: 3),
                      Text(prefs.formatDecimal(beerCount, 1),
                          style: smallStyle),
                      const SizedBox(width: 12),
                      Text(
                        TimeFormatter.formatCurrency(cost,
                            prefs: prefs, decimalPlaces: 0),
                        style: smallStyle,
                      ),
                    ],
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

/// Compact icon + text stat used in the keg level card.
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: BeerColors.onSurfaceSecondary),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BeerColors.onSurfaceSecondary,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
