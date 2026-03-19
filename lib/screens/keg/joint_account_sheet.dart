import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/repositories/joint_account_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
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
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
            myAccount != null ? 'My Joint Account' : 'Joint Accounts',
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, color: BeerColors.primaryAmber),
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
                  'Members',
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
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: user.id == uid
                                    ? BeerColors.primaryAmber
                                    : BeerColors.surfaceVariant,
                                child: Text(
                                  user.displayName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: user.id == uid
                                        ? BeerColors.background
                                        : BeerColors.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.displayName +
                                    (user.id == uid ? ' (you)' : ''),
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
                  error: (e, _) => Text('Error: $e'),
                ),
                // Add member — only for creator
                if (account.creatorId == uid) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () =>
                        _showAddMemberPicker(context, account),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add member'),
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
                  ? 'Delete account'
                  : 'Leave account',
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
          'Create a new group',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Group name (e.g. "Novák family")',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _isCreating ? null : () => _createAccount(uid),
          icon: const Icon(Icons.group_add),
          label: const Text('Create Group'),
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
          'Or join an existing group',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final account in joinable)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(
                Icons.group,
                color: BeerColors.primaryAmber,
              ),
              title: Text(account.groupName),
              subtitle: Text(
                '${account.memberUserIds.length} member(s)',
              ),
              trailing: TextButton(
                onPressed: () => _joinAccount(account.id, uid),
                child: const Text('Join'),
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
            const SnackBar(
              content: Text('You are already in a group.'),
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
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Failed to create group: $e')),
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
          const SnackBar(
            content:
                Text('You must leave your current group first.'),
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
    if (account.creatorId == uid) {
      // Creator deletes the whole account.
      await repo.deleteAccount(account.id);
    } else {
      // Member just leaves.
      await repo.removeMember(account.id, uid);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _showAddMemberPicker(
    BuildContext context,
    JointAccount account,
  ) {
    final eligibleIds = widget.participantIds
        .where((id) => !account.memberUserIds.contains(id))
        .toList();

    if (eligibleIds.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('All participants are already in a group.'),
          ),
        );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _MemberPickerSheet(
        eligibleIds: eligibleIds,
        onSelect: (userId) async {
          final repo = ref.read(jointAccountRepositoryProvider);
          // Verify the user isn't already in another group.
          final existing = await repo.getAccountForUser(
            widget.sessionId,
            userId,
          );
          if (existing != null && mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text(
                    'This user is already in another group.',
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

/// Simple picker sheet listing eligible participants to add.
class _MemberPickerSheet extends ConsumerWidget {
  const _MemberPickerSheet({
    required this.eligibleIds,
    required this.onSelect,
  });

  final List<String> eligibleIds;
  final Future<void> Function(String userId) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(watchUsersProvider(eligibleIds));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add member',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          usersAsync.when(
            data: (users) => Column(
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
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}
