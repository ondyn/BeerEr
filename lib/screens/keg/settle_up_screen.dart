import 'package:beerer/providers/providers.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/stats_calculator.dart';
import 'package:beerer/utils/time_formatter.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
        title: const Text('Export to Settle Up'),
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Session not found'));
          }

          final pours = poursAsync.value ?? [];
          final accounts = accountsAsync.value ?? [];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Review the bill split',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (accounts.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No joint accounts found. Individual costs will be exported.',
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
                            '${account.memberUserIds.length} members',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Total: ${TimeFormatter.formatCurrency(StatsCalculator.groupCost(pours, account.memberUserIds, session.kegPrice, session.volumeTotalMl))}',
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
                child: const Text('Export to Settle Up'),
              ),
              const SizedBox(height: 12),
              Text(
                'ℹ Settle Up will create a group with these amounts.',
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
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    try {
      final callable =
          FirebaseFunctions.instanceFor(region: 'europe-west1')
              .httpsCallable('exportToSettleUp');
      await callable.call<dynamic>({'sessionId': sessionId});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exported to Settle Up successfully!'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}
