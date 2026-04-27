import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/widgets/session_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Session history screen — past (done) sessions.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doneSessions = ref.watch(watchDoneSessionsProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
        title: Text(AppLocalizations.of(context)!.pastSessions),
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
                    AppLocalizations.of(context)!.noPastSessions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: BeerColors.onSurfaceSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: sessions.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HistorySessionCard(
                session: sessions[i],
                isOwner: sessions[i].creatorId == currentUserId,
                onTap: () => context.push('/keg/${sessions[i].id}'),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: BeerColors.primaryAmber),
        ),
        error: (e, _) => Center(
          child: Text(AppLocalizations.of(context)!.error(e.toString())),
        ),
      ),
    );
  }
}

/// Wraps [SessionCard] and watches the participant count from Firestore.
class _HistorySessionCard extends ConsumerWidget {
  const _HistorySessionCard({
    required this.session,
    required this.isOwner,
    this.onTap,
  });

  final KegSession session;
  final bool isOwner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One stream for the count — manual users and pour-based consumers are
    // not shown on the list card (acceptable UX trade-off to save reads).
    final participantIds =
        ref.watch(watchParticipantIdsProvider(session.id)).asData?.value ?? const [];
    final participantCount = participantIds.length;

    return SessionCard(
      session: session,
      participantCount: participantCount,
      isOwner: isOwner,
      onTap: onTap,
    );
  }
}
