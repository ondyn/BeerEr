import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/repositories/joint_account_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/widgets/avatar_icon.dart';
import 'package:beerer/widgets/avatar_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet for creating, joining, or managing a joint account
/// within a keg session.
class JointAccountSheet extends ConsumerStatefulWidget {
  const JointAccountSheet({
    super.key,
    required this.sessionId,
    required this.participantIds,
  });

  final String sessionId;
  final List<String> participantIds;

  @override
  ConsumerState<JointAccountSheet> createState() =>
      _JointAccountSheetState();
}

class _JointAccountSheetState extends ConsumerState<JointAccountSheet> {
  final _nameController = TextEditingController();
  bool _isCreating = false;
  int? _selectedAvatarIcon;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final accountsAsync =
        ref.watch(watchSessionAccountsProvider(widget.sessionId));
    final accounts = accountsAsync.asData?.value ?? [];
    final myAccount = accounts
        .where((a) => a.memberUserIds.contains(uid))
        .firstOrNull;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BeerColors.onSurfaceSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            myAccount != null ? AppLocalizations.of(context)!.myJointAccount : AppLocalizations.of(context)!.jointAccounts,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (myAccount != null)
            _buildMyAccount(context, myAccount, uid)
          else ...[
            _buildCreateSection(context, uid),
            if (accounts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildJoinSection(context, accounts, uid),
            ],
          ],
        ],
      ),
    );
  }

  /// Shows the user's current account with members and leave option.
  Widget _buildMyAccount(
    BuildContext context,
    JointAccount account,
    String uid,
  ) {
    final usersAsync = ref.watch(
      watchUsersProvider(account.memberUserIds),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account name
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GroupAvatarCircle(
                      avatarIcon: account.avatarIcon,
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        account.groupName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.members,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: BeerColors.onSurfaceSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                usersAsync.when(
                  data: (users) => Column(
                    children: [
                      for (final user in users)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              AvatarCircle(
                                displayName: user.displayName,
                                avatarIcon: user.avatarIcon,
                                radius: 14,
                                isHighlighted: user.id == uid,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.displayName +
                                    (user.id == uid ? ' ${AppLocalizations.of(context)!.youSuffix}' : ''),
                              ),
                              const Spacer(),
                              // Creator can remove members (except self)
                              if (account.creatorId == uid &&
                                  user.id != uid)
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                  ),
                                  onPressed: () => _removeMember(
                                    account.id,
                                    user.id,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())),
                ),
                // Add member — only for creator
                if (account.creatorId == uid) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () =>
                        _showAddMemberPicker(context, account),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: Text(AppLocalizations.of(context)!.addMember),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Leave / Delete
        Center(
          child: TextButton(
            onPressed: () => _leaveOrDelete(account, uid),
            child: Text(
              account.creatorId == uid
                  ? AppLocalizations.of(context)!.deleteAccount
                  : AppLocalizations.of(context)!.leaveAccount,
              style: const TextStyle(color: BeerColors.error),
            ),
          ),
        ),
      ],
    );
  }

  /// Create new group section.
  Widget _buildCreateSection(BuildContext context, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.createANewGroup,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Avatar picker
            GestureDetector(
              onTap: () async {
                final picked = await showAvatarPicker(
                  context,
                  currentCodePoint: _selectedAvatarIcon,
                );
                if (picked == null) return;
                setState(() {
                  _selectedAvatarIcon = picked == -1 ? null : picked;
                });
              },
              child: GroupAvatarCircle(
                avatarIcon: _selectedAvatarIcon,
                radius: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.groupNameHint,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _isCreating ? null : () => _createAccount(uid),
          icon: const Icon(Icons.group_add),
          label: Text(AppLocalizations.of(context)!.createGroup),
        ),
      ],
    );
  }

  /// Join existing group section.
  Widget _buildJoinSection(
    BuildContext context,
    List<JointAccount> accounts,
    String uid,
  ) {
    // Filter out accounts user already belongs to (shouldn't be any at
    // this point but just in case).
    final joinable =
        accounts.where((a) => !a.memberUserIds.contains(uid)).toList();
    if (joinable.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.orJoinExistingGroup,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final account in joinable)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: GroupAvatarCircle(
                avatarIcon: account.avatarIcon,
                radius: 18,
              ),
              title: Text(account.groupName),
              subtitle: Text(
                AppLocalizations.of(context)!.memberCount(account.memberUserIds.length),
              ),
              trailing: TextButton(
                onPressed: () => _joinAccount(account.id, uid),
                child: Text(AppLocalizations.of(context)!.join),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _createAccount(String uid) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);
    try {
      final repo = ref.read(jointAccountRepositoryProvider);
      // Check if user already created a group in this session.
      final existing = await repo.getAccountForUser(
        widget.sessionId,
        uid,
      );
      if (existing != null && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.alreadyInGroup),
            ),
          );
        setState(() => _isCreating = false);
        return;
      }

      await repo.createAccount(
        JointAccount(
          id: '',
          sessionId: widget.sessionId,
          groupName: name,
          creatorId: uid,
          memberUserIds: [uid],
          avatarIcon: _selectedAvatarIcon,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateGroup(e.toString()))),
          );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _joinAccount(String accountId, String uid) async {
    final repo = ref.read(jointAccountRepositoryProvider);
    // Check if already in a group.
    final existing = await repo.getAccountForUser(
      widget.sessionId,
      uid,
    );
    if (existing != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.leaveCurrentGroupFirst),
          ),
        );
      return;
    }
    await repo.addMember(accountId, uid);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _removeMember(
    String accountId,
    String userId,
  ) async {
    final repo = ref.read(jointAccountRepositoryProvider);
    await repo.removeMember(accountId, userId);
  }

  Future<void> _leaveOrDelete(
    JointAccount account,
    String uid,
  ) async {
    final repo = ref.read(jointAccountRepositoryProvider);
    try {
      if (account.creatorId == uid) {
        // Creator deletes the whole account.
        await repo.deleteAccount(account.id);
      } else {
        // Member just leaves.
        await repo.removeMember(account.id, uid);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.errorWithMessage(e.toString()),
              ),
            ),
          );
      }
    }
  }

  void _showAddMemberPicker(
    BuildContext context,
    JointAccount account,
  ) {
    final eligibleIds = widget.participantIds
        .where((id) => !account.memberUserIds.contains(id))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _MemberPickerSheet(
        eligibleIds: eligibleIds,
        sessionId: widget.sessionId,
        existingMemberIds: account.memberUserIds,
        onSelect: (userId) async {
          final repo = ref.read(jointAccountRepositoryProvider);
          final messenger = ScaffoldMessenger.of(context);
          final l10n = AppLocalizations.of(context)!;
          // Verify the user isn't already in another group.
          final existing = await repo.getAccountForUser(
            widget.sessionId,
            userId,
          );
          if (existing != null) {
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                  SnackBar(
                  content: Text(
                    l10n.userAlreadyInAnotherGroup,
                  ),
                ),
              );
            return;
          }
          await repo.addMember(account.id, userId);
        },
      ),
    );
  }
}

/// Simple picker sheet listing eligible participants (and guests) to add.
class _MemberPickerSheet extends ConsumerWidget {
  const _MemberPickerSheet({
    required this.eligibleIds,
    required this.sessionId,
    required this.existingMemberIds,
    required this.onSelect,
  });

  final List<String> eligibleIds;
  final String sessionId;
  final List<String> existingMemberIds;
  final Future<void> Function(String userId) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = eligibleIds.isNotEmpty
        ? ref.watch(watchUsersProvider(eligibleIds))
        : const AsyncValue<List<AppUser>>.data([]);
    final guestsAsync = ref.watch(watchManualUsersProvider(sessionId));

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.addMember,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          usersAsync.when(
            data: (users) {
              final guestList = guestsAsync.asData?.value ?? [];
              final eligibleGuests = guestList
                  .where((g) => !existingMemberIds.contains(g.id))
                  .toList();

              if (users.isEmpty && eligibleGuests.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    AppLocalizations.of(context)!.allParticipantsInGroup,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: BeerColors.onSurfaceSecondary,
                        ),
                  ),
                );
              }

              return Column(
                children: [
                  for (final user in users)
                    ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: BeerColors.surfaceVariant,
                        child: Text(
                          user.displayName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      title: Text(user.displayName),
                      onTap: () async {
                        await onSelect(user.id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  for (final guest in eligibleGuests)
                    ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: BeerColors.surfaceVariant,
                        child: const Icon(Icons.person_outline, size: 16),
                      ),
                      title: Text(guest.nickname),
                      subtitle: Text(AppLocalizations.of(context)!.guest),
                      onTap: () async {
                        await onSelect(guest.id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
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
      ),
    );
  }
}