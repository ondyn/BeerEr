import 'package:beerer/providers/providers.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/widgets/session_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Session history screen — past (done) sessions.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doneSessions = ref.watch(watchDoneSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: const Text('Past Sessions'),
      ),
      body: doneSessions.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.history,
                    size: 80,
                    color: BeerColors.surfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No past sessions',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color: BeerColors.onSurfaceSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SessionCard(
                session: sessions[i],
                onTap: () => context.push('/keg/${sessions[i].id}'),
              ),
            ),
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
}
