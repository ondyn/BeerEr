import 'package:beerer/models/models.dart';
import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/format_preferences.dart';
import 'package:beerer/utils/stats_calculator.dart';
import 'package:beerer/utils/time_formatter.dart';
import 'package:beerer/widgets/volume_picker_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bill review screen — allows the keg creator to inspect and adjust
/// every participant's consumption before finalising the bill.
class BillReviewScreen extends ConsumerWidget {
  const BillReviewScreen({super.key, required this.sessionId});

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
            appBar: AppBar(title: Text(AppLocalizations.of(context)!.reviewBill)),
            body: Center(child: Text(AppLocalizations.of(context)!.sessionNotFound)),
          );
        }
        return _BillReviewBody(
          session: session,
          poursAsync: poursAsync,
          participantIdsAsync: participantIdsAsync,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.reviewBill)),
        body: const Center(
          child: CircularProgressIndicator(
            color: BeerColors.primaryAmber,
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.reviewBill)),
        body: Center(child: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))),
      ),
    );
  }
}

class _BillReviewBody extends ConsumerWidget {
  const _BillReviewBody({
    required this.session,
    required this.poursAsync,
    required this.participantIdsAsync,
  });

  final KegSession session;
  final AsyncValue<List<Pour>> poursAsync;
  final AsyncValue<List<String>> participantIdsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pours = poursAsync.value ?? [];
    final participantIds = participantIdsAsync.value ?? [];
    final prefs = ref.watch(formatPreferencesProvider);

    final usersAsync = ref.watch(watchUsersProvider(participantIds));
    final users = usersAsync.asData?.value ?? [];

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

    final totalPoured = StatsCalculator.totalPouredMl(pours);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reviewBill),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          _SummaryCard(
            session: session,
            pours: pours,
            participantCount: participantIds.length,
            prefs: prefs,
          ),
          const SizedBox(height: 16),

          // Section heading
          Text(
            AppLocalizations.of(context)!.participantsLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),

          // Group accounts
          for (final account in accounts) ...[
            _GroupSection(
              account: account,
              pours: pours,
              users: users,
              session: session,
              prefs: prefs,
            ),
            const SizedBox(height: 8),
          ],

          // Solo users
          for (final user in soloUsers) ...[
            _ParticipantSection(
              user: user,
              pours: pours,
              session: session,
              prefs: prefs,
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 24),

          // Total info at bottom
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.totalConsumed,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: BeerColors.onSurfaceSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          TimeFormatter.formatVolumeMl(
                            totalPoured,
                            prefs: prefs,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.kegPriceLabel2,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: BeerColors.onSurfaceSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          TimeFormatter.formatCurrency(
                            session.kegPrice,
                            prefs: prefs,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.session,
    required this.pours,
    required this.participantCount,
    required this.prefs,
  });

  final KegSession session;
  final List<Pour> pours;
  final int participantCount;
  final FormatPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final totalPoured = StatsCalculator.totalPouredMl(pours);
    final pourCount = pours.where((p) => !p.undone).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long,
                    color: BeerColors.primaryAmber),
                const SizedBox(width: 8),
                Text(
                  session.beerName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _SummaryChip(
                  label: AppLocalizations.of(context)!.pours,
                  value: '$pourCount',
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  label: AppLocalizations.of(context)!.drinkers,
                  value: '$participantCount',
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  label: AppLocalizations.of(context)!.total,
                  value: TimeFormatter.formatVolumeMl(
                    totalPoured,
                    prefs: prefs,
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: BeerColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BeerColors.onSurfaceSecondary,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single participant section with expandable pour list
// ---------------------------------------------------------------------------

class _ParticipantSection extends ConsumerWidget {
  const _ParticipantSection({
    required this.user,
    required this.pours,
    required this.session,
    required this.prefs,
  });

  final AppUser user;
  final List<Pour> pours;
  final KegSession session;
  final FormatPreferences prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMe = user.id == uid;
    final userPours =
        pours.where((p) => p.userId == user.id && !p.undone).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final volumeMl = StatsCalculator.userPouredMl(pours, user.id);
    final ratio = StatsCalculator.userConsumptionRatio(pours, user.id);
    final cost = StatsCalculator.userCostByConsumption(
      pours,
      user.id,
      session.kegPrice,
    );

    return _ExpandableParticipantCard(
      title: user.displayName + (isMe ? AppLocalizations.of(context)!.youSuffix : ''),
      subtitle:
          '${TimeFormatter.formatVolumeMl(volumeMl, prefs: prefs)} · '
          '${TimeFormatter.formatRatio(ratio)}',
      cost: TimeFormatter.formatCurrency(cost, prefs: prefs),
      avatarLetter: user.displayName[0].toUpperCase(),
      isHighlighted: isMe,
      pourCount: userPours.length,
      userPours: userPours,
      session: session,
      userId: user.id,
      userName: user.displayName,
      prefs: prefs,
    );
  }
}

// ---------------------------------------------------------------------------
// Group section — group header + individual members
// ---------------------------------------------------------------------------

class _GroupSection extends ConsumerWidget {
  const _GroupSection({
    required this.account,
    required this.pours,
    required this.users,
    required this.session,
    required this.prefs,
  });

  final JointAccount account;
  final List<Pour> pours;
  final List<AppUser> users;
  final KegSession session;
  final FormatPreferences prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupCost = StatsCalculator.groupCostByConsumption(
      pours,
      account.memberUserIds,
      session.kegPrice,
    );
    final groupVolumeMl = StatsCalculator.groupPouredMl(
      pours,
      account.memberUserIds,
    );
    final groupRatio = StatsCalculator.groupConsumptionRatio(
      pours,
      account.memberUserIds,
    );

    final memberUsers = account.memberUserIds
        .map((id) => users.where((u) => u.id == id).firstOrNull)
        .whereType<AppUser>()
        .toList();

    return Card(
      color: BeerColors.primaryAmber.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Row(
              children: [
                const Icon(Icons.group,
                    size: 20, color: BeerColors.primaryAmber),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.groupName,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${TimeFormatter.formatVolumeMl(groupVolumeMl, prefs: prefs)} · '
                        '${TimeFormatter.formatRatio(groupRatio)}',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: BeerColors.onSurfaceSecondary,
                                ),
                      ),
                    ],
                  ),
                ),
                Text(
                  TimeFormatter.formatCurrency(groupCost, prefs: prefs),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Divider(height: 16),
            // Individual members
            for (final member in memberUsers) ...[
              _ParticipantSection(
                user: member,
                pours: pours,
                session: session,
                prefs: prefs,
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable participant card with pour list + add/remove actions
// ---------------------------------------------------------------------------

class _ExpandableParticipantCard extends ConsumerStatefulWidget {
  const _ExpandableParticipantCard({
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.avatarLetter,
    required this.isHighlighted,
    required this.pourCount,
    required this.userPours,
    required this.session,
    required this.userId,
    required this.userName,
    required this.prefs,
  });

  final String title;
  final String subtitle;
  final String cost;
  final String avatarLetter;
  final bool isHighlighted;
  final int pourCount;
  final List<Pour> userPours;
  final KegSession session;
  final String userId;
  final String userName;
  final FormatPreferences prefs;

  @override
  ConsumerState<_ExpandableParticipantCard> createState() =>
      _ExpandableParticipantCardState();
}

class _ExpandableParticipantCardState
    extends ConsumerState<_ExpandableParticipantCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header — tap to expand
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: widget.isHighlighted
                        ? BeerColors.primaryAmber
                        : BeerColors.surfaceVariant,
                    child: Text(
                      widget.avatarLetter,
                      style: TextStyle(
                        color: widget.isHighlighted
                            ? BeerColors.background
                            : BeerColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: BeerColors.onSurfaceSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.cost,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: BeerColors.onSurfaceSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable pour list
          if (_expanded) ...[
            const Divider(height: 1),
            // Pour rows
            if (widget.userPours.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.noPours,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BeerColors.onSurfaceSecondary,
                      ),
                ),
              )
            else
              for (final pour in widget.userPours)
                _PourRow(
                  pour: pour,
                  session: widget.session,
                  prefs: widget.prefs,
                ),

            // Add pour button
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: () => _addPour(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(AppLocalizations.of(context)!.addBeerFor(widget.userName)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addPour(BuildContext context) async {
    // Re-activate the keg temporarily to allow the pour transaction,
    // then mark it done again. Alternatively, add the pour directly.
    // The simplest approach: use the keg repo which requires active status.
    // Instead, we'll create the pour directly so the done status is preserved.
    final volumeMl = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VolumePickerSheet(
        predefinedVolumesMl: widget.session.predefinedVolumesMl,
        title: AppLocalizations.of(context)!.addBeerFor(widget.userName),
      ),
    );

    if (volumeMl == null || !context.mounted) return;

    HapticFeedback.mediumImpact();

    final creatorUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final pour = Pour(
      id: '',
      sessionId: widget.session.id,
      userId: widget.userId,
      pouredById: creatorUid,
      volumeMl: volumeMl,
      timestamp: DateTime.now(),
    );

    try {
      final repo = ref.read(kegRepositoryProvider);
      final created = await repo.addPourForReview(pour);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.addedVolumeFor(TimeFormatter.formatVolumeMl(volumeMl, prefs: widget.prefs), widget.userName)),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.undo,
                onPressed: () {
                  repo.undoPourForReview(created);
                },
              ),
            ),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToAddPour)),
          );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Individual pour row with remove (undo) button
// ---------------------------------------------------------------------------

class _PourRow extends ConsumerWidget {
  const _PourRow({
    required this.pour,
    required this.session,
    required this.prefs,
  });

  final Pour pour;
  final KegSession session;
  final FormatPreferences prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = pour.timestamp;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.sports_bar,
              size: 16, color: BeerColors.primaryAmber),
          const SizedBox(width: 8),
          Text(
            TimeFormatter.formatVolumeMl(pour.volumeMl, prefs: prefs),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BeerColors.onSurfaceSecondary,
                ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _removePour(context, ref),
            icon: const Icon(Icons.remove_circle_outline,
                size: 20, color: BeerColors.error),
            tooltip: AppLocalizations.of(context)!.removePourTooltip,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _removePour(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removePourQuestion),
        content: Text(
          AppLocalizations.of(context)!.removePourConfirm(TimeFormatter.formatVolumeMl(pour.volumeMl, prefs: prefs)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(kegRepositoryProvider).undoPourForReview(pour);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.pourRemoved)),
                  );
              }
            },
            child: Text(AppLocalizations.of(context)!.remove),
          ),
        ],
      ),
    );
  }
}

