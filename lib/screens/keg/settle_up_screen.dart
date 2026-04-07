import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/stats_calculator.dart';
import 'package:beerer/utils/time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Export to Settle Up screen — creator only, after keg done.
class SettleUpScreen extends ConsumerWidget {
  const SettleUpScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(watchSessionProvider(sessionId));
    final poursAsync = ref.watch(watchSessionPoursProvider(sessionId));
    final accountsAsync =
        ref.watch(watchSessionAccountsProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context)!.exportToSettleUp),
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return Center(child: Text(AppLocalizations.of(context)!.sessionNotFound));
          }

          final pours = poursAsync.value ?? [];
          final accounts = accountsAsync.value ?? [];
          final prefs = ref.watch(formatPreferencesProvider)
              .withCurrency(session.currency);

          return ListView(
            padding: EdgeInsets.fromLTRB(
              24, 24, 24,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Text(
                AppLocalizations.of(context)!.reviewBillSplit,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (accounts.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context)!.noJointAccountsFound,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                for (final account in accounts)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.group,
                                color: BeerColors.primaryAmber,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                account.groupName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.membersCount(account.memberUserIds.length),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            AppLocalizations.of(context)!.totalWithAmount(TimeFormatter.formatCurrency(StatsCalculator.groupCost(pours, account.memberUserIds, session.kegPrice, session.volumeTotalMl), prefs: prefs)),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _export(context),
                child: Text(AppLocalizations.of(context)!.exportToSettleUp),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.settleUpInfo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BeerColors.onSurfaceSecondary,
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
        error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    // Settle Up export is not yet implemented without Cloud Functions.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.settleUpInfo),
        ),
      );
    }
  }
}
