import 'dart:async';
import 'dart:convert';

import 'package:beerer/models/models.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

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
  final _beerWebSearchController = TextEditingController();
  final _beerNameController = TextEditingController();
  // Optional beer-detail fields sourced from BeerWeb.cz
  final _alcoholController = TextEditingController();
  final _breweryController = TextEditingController();
  final _maltController = TextEditingController();
  final _fermentationController = TextEditingController();
  final _beerTypeController = TextEditingController();
  final _beerGroupController = TextEditingController();
  final _beerStyleController = TextEditingController();
  final _degreePlatoController = TextEditingController();
  List<_BeerWebResult> _beerWebResults = [];
  bool _beerWebSearching = false;
  Timer? _debounce;

  // Step 2 fields
  final _volumeController = TextEditingController(text: '30');
  final _priceController = TextEditingController(text: '100.00');
  final List<double> _predefinedVolumes = [500, 300];

  bool _isCreating = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _beerWebSearchController.dispose();
    _beerNameController.dispose();
    _alcoholController.dispose();
    _breweryController.dispose();
    _maltController.dispose();
    _fermentationController.dispose();
    _beerTypeController.dispose();
    _beerGroupController.dispose();
    _beerStyleController.dispose();
    _degreePlatoController.dispose();
    _volumeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onBeerWebSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _beerWebResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchBeerWeb(query.trim());
    });
  }

  Future<void> _searchBeerWeb(String query) async {
    setState(() => _beerWebSearching = true);
    try {
      final uri = Uri.parse(
        'https://beerweb.cz/api/Search?term=${Uri.encodeComponent(query)}',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final results = _parseBeerWebResponse(response.body);
        setState(() => _beerWebResults = results);
      } else {
        setState(() => _beerWebResults = []);
      }
    } catch (_) {
      setState(() => _beerWebResults = []);
    } finally {
      setState(() => _beerWebSearching = false);
    }
  }

  /// Parses BeerWeb JSON (or XML fallback) and returns only beer items
  /// whose Name ends with ", pivo".
  List<_BeerWebResult> _parseBeerWebResponse(String body) {
    final results = <_BeerWebResult>[];
    try {
      final list = jsonDecode(body) as List<dynamic>;
      for (final item in list) {
        final name = (item as Map<String, dynamic>)['Name'] as String? ?? '';
        final url = item['Url'] as String? ?? '';
        if (name.endsWith(', pivo')) {
          results.add(_BeerWebResult(name: name, url: url));
        }
      }
    } catch (_) {
      // Fallback: try XML regex if server ever returns XML
      final blockRe = RegExp(
        r'<NameUrlViewModel>(.*?)</NameUrlViewModel>',
        dotAll: true,
      );
      final nameRe = RegExp(r'<Name>(.*?)</Name>');
      final urlRe = RegExp(r'<Url>(.*?)</Url>');
      for (final block in blockRe.allMatches(body)) {
        final content = block.group(1) ?? '';
        final name = nameRe.firstMatch(content)?.group(1) ?? '';
        final url = urlRe.firstMatch(content)?.group(1) ?? '';
        if (name.endsWith(', pivo')) {
          results.add(_BeerWebResult(name: name, url: url));
        }
      }
    }
    return results;
  }

  Future<void> _selectBeerWebResult(_BeerWebResult result) async {
    // Strip the ", pivo" suffix for the beer name field
    final cleanName = result.name.endsWith(', pivo')
        ? result.name.substring(0, result.name.length - ', pivo'.length)
        : result.name;

    setState(() {
      _beerNameController.text = cleanName;
      _beerWebResults = [];
      _beerWebSearchController.clear();
    });

    // Fetch detail page and parse alcohol %
    await _fetchAlcohol(result.url);
  }

  Future<void> _fetchAlcohol(String urlPath) async {
    try {
      final uri = Uri.parse('https://beerweb.cz$urlPath');
      final response = await http.get(uri);
      if (response.statusCode != 200) return;
      final body = response.body;

      // The BeerWeb detail page uses:
      //   <span class="bold_text">LABEL: </span>\n                VALUE<br />
      // or with a link:
      //   <span class="bold_text">LABEL: </span>\n                <a …>VALUE</a><br />
      // We match across newlines with dotAll and stop at '<' for plain values.
      String? extract(String label) {
        final re = RegExp(
          r'<span[^>]*class="bold_text"[^>]*>\s*' +
              RegExp.escape(label) +
              r':\s*</span>\s*(?:<a[^>]*>([^<]+)</a>|([^<]+?)\s*<)',
          caseSensitive: false,
          dotAll: true,
        );
        final m = re.firstMatch(body);
        if (m == null) return null;
        return (m.group(1) ?? m.group(2))?.trim();
      }

      // Alcohol % — value looks like "6,2% vol.", strip non-numeric suffix
      final rawAlcohol = extract('Alkohol');
      if (rawAlcohol != null) {
        // Value looks like "3,8% vol." — extract the leading decimal number only.
        final numStr = rawAlcohol.replaceAll(',', '.');
        final numMatch = RegExp(r'\d+\.?\d*').firstMatch(numStr);
        final value = numMatch != null ? double.tryParse(numMatch.group(0)!) : null;
        if (value != null && mounted) {
          setState(() => _alcoholController.text = value.toString());
        }
      }

      // Brewery (Pivovar) — value is a link, e.g. <a …>Pivovar Kamenice nad Lipou</a>
      final brewery = extract('Pivovar');
      if (brewery != null && mounted) {
        setState(() => _breweryController.text = brewery);
      }

      // Malt (Slad) — plain text, e.g. "ječný"
      final malt = extract('Slad');
      if (malt != null && mounted) {
        setState(() => _maltController.text = malt);
      }

      // Fermentation (Kvašení) — plain text, e.g. "svrchní"
      final fermentation = extract('Kvašení');
      if (fermentation != null && mounted) {
        setState(
          () => _fermentationController.text =
              _translateFermentation(fermentation),
        );
      }

      // Type (Druh) — plain text, e.g. "světlé"
      final beerType = extract('Druh');
      if (beerType != null && mounted) {
        setState(() => _beerTypeController.text = _translateType(beerType));
      }

      // Group (Skupina) — plain text, e.g. "plné"
      final beerGroup = extract('Skupina');
      if (beerGroup != null && mounted) {
        setState(
          () => _beerGroupController.text = _translateGroup(beerGroup),
        );
      }

      // Beer style (Pivní styl) — value is a link, e.g. <a …>Pale Ale</a>
      final beerStyle = extract('Pivní styl');
      if (beerStyle != null && mounted) {
        setState(() => _beerStyleController.text = beerStyle);
      }

      // Degree Plato (Stupňovitost/EPM) — plain text, e.g. "12°"
      final degreePlato = extract('Stupňovitost/EPM');
      if (degreePlato != null && mounted) {
        // Keep only digits/decimal, strip the ° symbol
        final cleaned = degreePlato
            .replaceAll(RegExp(r'[^\d,.]'), '')
            .replaceAll(',', '.');
        setState(
          () => _degreePlatoController.text =
              cleaned.isNotEmpty ? cleaned : degreePlato,
        );
      }
    } catch (_) {
      // Non-critical — user can adjust manually
    }
  }

  /// Translates Czech fermentation term to English.
  String _translateFermentation(String czech) {
    switch (czech.toLowerCase().trim()) {
      case 'svrchní':
        return 'Top-fermented';
      case 'spodní':
        return 'Bottom-fermented';
      case 'spontánní':
        return 'Spontaneous';
      case 'smíšené':
        return 'Mixed';
      default:
        return czech;
    }
  }

  /// Translates Czech beer type (Druh) to English.
  String _translateType(String czech) {
    switch (czech.toLowerCase().trim()) {
      case 'světlé':
        return 'Pale';
      case 'tmavé':
        return 'Dark';
      case 'polotmavé':
        return 'Semi-dark';
      case 'černé':
        return 'Black';
      case 'řezané':
        return 'Mixed';
      case 'nefiltrované':
        return 'Unfiltered';
      case 'ochucené':
        return 'Flavoured';
      default:
        return czech;
    }
  }

  /// Translates Czech beer group (Skupina) to English.
  String _translateGroup(String czech) {
    switch (czech.toLowerCase().trim()) {
      case 'výčepní':
        return 'Draft';
      case 'plné':
        return 'Full';
      case 'speciální':
        return 'Special';
      case 'silné':
        return 'Strong';
      case 'lehké':
        return 'Light';
      default:
        return czech;
    }
  }

  Future<void> _createSession() async {
    if (!_formKey2.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isCreating = true);

    try {
      final repo = ref.read(kegRepositoryProvider);
      final volumeLitres =
          double.parse(_volumeController.text.replaceAll(',', '.'));
      final alcoholText =
          _alcoholController.text.trim().replaceAll(',', '.');
      final session = KegSession(
        id: '',
        creatorId: user.uid,
        beerName: _beerNameController.text.trim(),
        untappdBeerId: null,
        volumeTotalMl: volumeLitres * 1000,
        volumeRemainingMl: volumeLitres * 1000,
        kegPrice: double.parse(
          _priceController.text.replaceAll(',', '.'),
        ),
        alcoholPercent: double.tryParse(alcoholText) ?? 0.0,
        predefinedVolumesMl: _predefinedVolumes,
        brewery: _breweryController.text.trim().isNotEmpty
            ? _breweryController.text.trim()
            : null,
        malt: _maltController.text.trim().isNotEmpty
            ? _maltController.text.trim()
            : null,
        fermentation: _fermentationController.text.trim().isNotEmpty
            ? _fermentationController.text.trim()
            : null,
        beerType: _beerTypeController.text.trim().isNotEmpty
            ? _beerTypeController.text.trim()
            : null,
        beerGroup: _beerGroupController.text.trim().isNotEmpty
            ? _beerGroupController.text.trim()
            : null,
        beerStyle: _beerStyleController.text.trim().isNotEmpty
            ? _beerStyleController.text.trim()
            : null,
        degreePlato: _degreePlatoController.text.trim().isNotEmpty
            ? _degreePlatoController.text.trim()
            : null,
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
                final val = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );
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
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
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
            // BeerWeb search
            TextField(
              controller: _beerWebSearchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: 'Search beer on BeerWeb…',
                hintText: 'e.g. Kozel',
                suffixIcon: _beerWebSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _beerWebSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _beerWebSearchController.clear();
                              setState(() => _beerWebResults = []);
                            },
                          )
                        : null,
              ),
              onChanged: _onBeerWebSearchChanged,
              textInputAction: TextInputAction.search,
            ),
            if (_beerWebResults.isNotEmpty) ...[
              const SizedBox(height: 4),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: _beerWebResults.take(7).map((result) {
                    // Strip ", pivo" suffix for display
                    final displayName = result.name.endsWith(', pivo')
                        ? result.name.substring(
                            0, result.name.length - ', pivo'.length)
                        : result.name;
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.sports_bar,
                        color: BeerColors.primaryAmber,
                      ),
                      title: Text(displayName),
                      onTap: () => _selectBeerWebResult(result),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            Text(
              'Beer details (optional)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _alcoholController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Alcohol content (%)',
                hintText: 'e.g. 5.0',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _breweryController,
              decoration: const InputDecoration(
                labelText: 'Brewery',
                hintText: 'e.g. Pilsner Urquell Brewery',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maltController,
              decoration: const InputDecoration(
                labelText: 'Malt',
                hintText: 'e.g. barley',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fermentationController,
              decoration: const InputDecoration(
                labelText: 'Fermentation',
                hintText: 'e.g. Bottom-fermented',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _beerTypeController,
              decoration: const InputDecoration(
                labelText: 'Type',
                hintText: 'e.g. Pale',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _beerGroupController,
              decoration: const InputDecoration(
                labelText: 'Group',
                hintText: 'e.g. Full',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _beerStyleController,
              decoration: const InputDecoration(
                labelText: 'Beer style',
                hintText: 'e.g. Pale Ale',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _degreePlatoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Degree Plato (°P)',
                hintText: 'e.g. 12',
              ),
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
            Text(
              'Keg volume (litres)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final volume in [50, 30, 20, 15, 10])
                  ChoiceChip(
                    label: Text('$volume L'),
                    selected: _volumeController.text == volume.toString(),
                    onSelected: (selected) {
                      if (selected) {
                        setState(
                          () => _volumeController.text = volume.toString(),
                        );
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _volumeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Or enter custom volume',
                hintText: 'e.g. 25',
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

/// Simple data class representing a beer result from beerweb.cz.
class _BeerWebResult {
  const _BeerWebResult({required this.name, required this.url});
  final String name;
  final String url;
}
