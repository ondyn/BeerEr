import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Create keg session — two-step form.
class CreateKegScreen extends ConsumerStatefulWidget {
  const CreateKegScreen({super.key});

  @override
  ConsumerState<CreateKegScreen> createState() => _CreateKegScreenState();
}

class _CreateKegScreenState extends ConsumerState<CreateKegScreen> {
  int _step = 1;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Step 1 fields
  final _searchController = TextEditingController();
  final _beerNameController = TextEditingController();
  final _volumeController = TextEditingController(text: '30');
  final _alcoholController = TextEditingController(text: '4.4');
  String? _untappdBeerId;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;

  // Step 2 fields
  final _priceController = TextEditingController(text: '100.00');
  final List<double> _predefinedVolumes = [500, 300];

  bool _isCreating = false;

  @override
  void dispose() {
    _searchController.dispose();
    _beerNameController.dispose();
    _volumeController.dispose();
    _alcoholController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _searchUntappd(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _searching = true);

    try {
      final callable =
          FirebaseFunctions.instanceFor(region: 'europe-west1')
              .httpsCallable('searchUntappd');
      final result = await callable.call<dynamic>({'query': query});
      final items = (result.data as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      setState(() => _searchResults = items);
    } catch (_) {
      // Search failed — user can still enter free text
      setState(() => _searchResults = []);
    } finally {
      setState(() => _searching = false);
    }
  }

  void _selectBeer(Map<String, dynamic> beer) {
    setState(() {
      _beerNameController.text = beer['beer_name'] as String? ?? '';
      _untappdBeerId = beer['bid']?.toString();
      _alcoholController.text =
          (beer['beer_abv'] as num?)?.toString() ?? '4.4';
      _searchResults = [];
      _searchController.clear();
    });
  }

  Future<void> _createSession() async {
    if (!_formKey2.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isCreating = true);

    try {
      final repo = ref.read(kegRepositoryProvider);
      final volumeLitres = double.parse(_volumeController.text);
      final session = KegSession(
        id: '',
        creatorId: user.uid,
        beerName: _beerNameController.text.trim(),
        untappdBeerId: _untappdBeerId,
        volumeTotalMl: volumeLitres * 1000,
        volumeRemainingMl: volumeLitres * 1000,
        kegPrice: double.parse(_priceController.text),
        alcoholPercent: double.parse(_alcoholController.text),
        predefinedVolumesMl: _predefinedVolumes,
      );

      final created = await repo.createSession(session);
      // Also add creator as participant
      await repo.addParticipant(created.id, user.uid);

      if (mounted) context.go('/keg/${created.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create session: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _addPredefinedVolume() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add pour size'),
          content: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Volume (ml)',
              hintText: 'e.g. 500',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final val = double.tryParse(controller.text);
                if (val != null && val > 0) {
                  setState(() => _predefinedVolumes.add(val));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: Text('New Keg Session  $_step/2'),
      ),
      body: SafeArea(
        child: _step == 1 ? _buildStep1() : _buildStep2(),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Untappd search
            // TextField(
            //   controller: _searchController,
            //   decoration: InputDecoration(
            //     prefixIcon: const Icon(Icons.search),
            //     labelText: 'Search beer…',
            //     suffixIcon: _searching
            //         ? const Padding(
            //             padding: EdgeInsets.all(12),
            //             child: SizedBox(
            //               width: 20,
            //               height: 20,
            //               child: CircularProgressIndicator(
            //                 strokeWidth: 2,
            //               ),
            //             ),
            //           )
            //         : null,
            //   ),
            //   onSubmitted: _searchUntappd,
            //   textInputAction: TextInputAction.search,
            // ),
            // const SizedBox(height: 8),
            // // Search results
            // if (_searchResults.isNotEmpty)
            //   ...(_searchResults.take(5).map((beer) => Card(
            //         child: ListTile(
            //           leading: const Icon(
            //             Icons.sports_bar,
            //             color: BeerColors.primaryAmber,
            //           ),
            //           title: Text(
            //             beer['beer_name'] as String? ?? '',
            //           ),
            //           subtitle: Text(
            //             '${beer['brewery_name'] ?? ''} · '
            //             '${beer['beer_abv'] ?? ''}% ABV',
            //           ),
            //           onTap: () => _selectBeer(beer),
            //         ),
            //       ))),
            // const SizedBox(height: 16),
            // Text(
            //   'Or enter beer name:',
            //   style: Theme.of(context).textTheme.bodySmall,
            // ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _beerNameController,
              decoration: const InputDecoration(
                labelText: 'Beer name',
                hintText: 'e.g. Pilsner Urquell',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a beer name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _volumeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Keg volume (litres)',
              ),
              validator: (val) {
                if (val == null || double.tryParse(val) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alcoholController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Alcohol content (%)',
              ),
              validator: (val) {
                if (val == null || double.tryParse(val) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                if (_formKey1.currentState!.validate()) {
                  setState(() => _step = 2);
                }
              },
              child: const Text('Next →'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Keg price (€)',
              ),
              validator: (val) {
                if (val == null || double.tryParse(val) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Predefined pour sizes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap × to remove',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < _predefinedVolumes.length; i++)
                  Chip(
                    label: Text(
                      '${(_predefinedVolumes[i] / 1000).toStringAsFixed(1)}l',
                    ),
                    onDeleted: () {
                      setState(
                        () => _predefinedVolumes.removeAt(i),
                      );
                    },
                  ),
                ActionChip(
                  label: const Text('+ Add'),
                  onPressed: _addPredefinedVolume,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('← Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isCreating ? null : _createSession,
                    child: _isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: BeerColors.background,
                            ),
                          )
                        : const Text('Create Session'),
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
