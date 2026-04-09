import 'dart:async';

import 'package:beerer/l10n/app_localizations.dart';
import 'package:beerer/models/models.dart';
import 'package:beerer/providers/providers.dart';
import 'package:beerer/repositories/keg_repository.dart';
import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/utils/format_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _beerSearchController = TextEditingController();
  final _beerNameController = TextEditingController();
  // Optional beer-detail fields
  final _alcoholController = TextEditingController();
  final _breweryController = TextEditingController();
  final _maltController = TextEditingController();
  final _fermentationController = TextEditingController();
  final _beerTypeController = TextEditingController();
  final _beerGroupController = TextEditingController();
  final _beerStyleController = TextEditingController();
  final _degreePlatoController = TextEditingController();
  List<_BeerSearchResult> _beerSearchResults = [];
  bool _beerSearching = false;
  Timer? _debounce;
  // Brewery details fetched when a beer is selected
  String? _breweryAddress;
  String? _breweryRegion;
  String? _breweryYearFounded;
  String? _breweryWebsite;

  // Step 2 fields
  final _volumeController = TextEditingController(text: '30');
  final _priceController = TextEditingController();
  final List<double> _predefinedVolumes = [500, 300];
  String _selectedCurrency = '€';

  bool _isCreating = false;
  bool _prefsInitialized = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _beerSearchController.dispose();
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

  void _onBeerSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      setState(() => _beerSearchResults = []);
      return;
    }
    // Immediate search at exactly 3 chars; longer debounce for 4+ chars.
    if (trimmed.length == 3) {
      _searchBeers(trimmed);
    } else {
      _debounce = Timer(const Duration(milliseconds: 600), () {
        _searchBeers(trimmed);
      });
    }
  }

  /// Strips diacritics/accents from [input] using Unicode NFD decomposition.
  static String _removeDiacritics(String input) {
    // Decompose to NFD, then strip combining marks (U+0300..U+036F).
    final nfd = input.replaceAllMapped(
      RegExp(r'[\u00C0-\u024F]'),
      (m) {
        // Normalize the single char via a lookup of common Latin accented chars.
        return m.group(0)!;
      },
    );
    // Use a comprehensive approach: normalize and strip combining characters.
    return nfd
        .replaceAll(RegExp('[\u0300-\u036f]'), '')
        .replaceAllMapped(RegExp(r'[àáâãäå]'), (_) => 'a')
        .replaceAllMapped(RegExp(r'[èéêë]'), (_) => 'e')
        .replaceAllMapped(RegExp(r'[ìíîï]'), (_) => 'i')
        .replaceAllMapped(RegExp(r'[òóôõö]'), (_) => 'o')
        .replaceAllMapped(RegExp(r'[ùúûü]'), (_) => 'u')
        .replaceAllMapped(RegExp(r'[ýÿ]'), (_) => 'y')
        .replaceAllMapped(RegExp(r'[ñ]'), (_) => 'n')
        .replaceAllMapped(RegExp(r'[čć]'), (_) => 'c')
        .replaceAllMapped(RegExp(r'[řŕ]'), (_) => 'r')
        .replaceAllMapped(RegExp(r'[šś]'), (_) => 's')
        .replaceAllMapped(RegExp(r'[žź]'), (_) => 'z')
        .replaceAllMapped(RegExp(r'[ťṫ]'), (_) => 't')
        .replaceAllMapped(RegExp(r'[ďḋ]'), (_) => 'd')
        .replaceAllMapped(RegExp(r'[ňṅ]'), (_) => 'n')
        .replaceAllMapped(RegExp(r'[ůű]'), (_) => 'u')
        .replaceAllMapped(RegExp(r'[ě]'), (_) => 'e')
        .replaceAllMapped(RegExp(r'[ľĺ]'), (_) => 'l')
        .replaceAllMapped(RegExp(r'[ä]'), (_) => 'a')
        .replaceAllMapped(RegExp(r'[ö]'), (_) => 'o')
        .replaceAllMapped(RegExp(r'[ü]'), (_) => 'u');
  }

  Future<void> _searchBeers(String query) async {
    setState(() => _beerSearching = true);
    try {
      // Normalize: lowercase, remove diacritics, split into words.
      final normalized = _removeDiacritics(query.toLowerCase());
      final words = normalized
          .split(RegExp(r'[\s\W]+'))
          .where((w) => w.length >= 2)
          .toList();
      if (words.isEmpty) {
        if (mounted) setState(() => _beerSearchResults = []);
        return;
      }

      // Use the longest word for the Firestore array-contains query
      // (most selective). Remaining words are filtered client-side.
      final queryWord = words.reduce(
        (a, b) => a.length >= b.length ? a : b,
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('beers')
          .where('search_terms', arrayContains: queryWord)
          .limit(50)
          .get();

      // Client-side: filter results so ALL query words appear in the
      // combined name + brewery (both normalized).
      final results = <_BeerSearchResult>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final nameLower = data['name_lower'] as String? ?? '';
        final breweryLower = _removeDiacritics(
          (data['brewery_name'] as String? ?? '').toLowerCase(),
        );
        final combined = '$nameLower $breweryLower';
        final matches = words.every((w) => combined.contains(w));
        if (matches) {
          results.add(_BeerSearchResult(
            name: data['name'] as String? ?? '',
            breweryName: data['brewery_name'] as String? ?? '',
            breweryId: data['brewery_id'] as String?,
            alcoholPercent: (data['alcohol_percent'] as num?)?.toDouble(),
            epm: data['epm'] as String?,
            malt: data['malt'] as String?,
            fermentation: data['fermentation'] as String?,
            type: data['type'] as String?,
            group: data['group'] as String?,
            beerStyle: data['beer_style'] as String?,
          ));
        }
      }

      if (mounted) setState(() => _beerSearchResults = results);
    } catch (_) {
      if (mounted) setState(() => _beerSearchResults = []);
    } finally {
      if (mounted) setState(() => _beerSearching = false);
    }
  }

  Future<void> _selectBeerSearchResult(_BeerSearchResult result) async {
    setState(() {
      _beerNameController.text = result.name;
      _beerSearchController.clear();
      _beerSearchResults = [];
      _breweryAddress = null;
      _breweryRegion = null;
      _breweryYearFounded = null;
      _breweryWebsite = null;
      if (result.alcoholPercent != null) {
        _alcoholController.text = result.alcoholPercent.toString();
      }
      if (result.breweryName.isNotEmpty) {
        _breweryController.text = result.breweryName;
      }
      if (result.malt != null) {
        _maltController.text = result.malt!;
      }
      if (result.fermentation != null) {
        _fermentationController.text = result.fermentation!;
      }
      if (result.type != null) {
        _beerTypeController.text = result.type!;
      }
      if (result.group != null) {
        _beerGroupController.text = result.group!;
      }
      if (result.beerStyle != null) {
        _beerStyleController.text = result.beerStyle!;
      }
      if (result.epm != null) {
        _degreePlatoController.text =
            result.epm!.replaceAll('°', '').trim();
      }
    });
    if (result.breweryId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('breweries')
            .doc(result.breweryId)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _breweryAddress = data['address'] as String?;
            _breweryRegion = data['region'] as String?;
            final yearFounded = data['year_founded'];
            _breweryYearFounded = yearFounded?.toString();
            _breweryWebsite = data['website'] as String?;
          });
        }
      } catch (_) {}
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
        volumeTotalMl: volumeLitres * 1000,
        volumeRemainingMl: volumeLitres * 1000,
        kegPrice: double.parse(
          _priceController.text.replaceAll(',', '.'),
        ),
        alcoholPercent: double.tryParse(alcoholText) ?? 0.0,
        predefinedVolumesMl: _predefinedVolumes,
        currency: _selectedCurrency,
        brewery: _breweryController.text.trim().isNotEmpty
            ? _breweryController.text.trim()
            : null,
        breweryAddress: _breweryAddress,
        breweryRegion: _breweryRegion,
        breweryYearFounded: _breweryYearFounded,
        breweryWebsite: _breweryWebsite,
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

      if (mounted) context.pushReplacement('/keg/${created.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateSession(e.toString()))),
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
          title: Text(AppLocalizations.of(context)!.addPourSize),
          content: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.volumeMl,
              hintText: AppLocalizations.of(context)!.egPourSize,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
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
              child: Text(AppLocalizations.of(context)!.add),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(formatPreferencesProvider);

    // Set default price text with correct decimal separator on first build.
    if (!_prefsInitialized) {
      _prefsInitialized = true;
      _priceController.text = prefs.formatDecimal(100, 2);
      _selectedCurrency = prefs.currency;
    }

    return PopScope(
      canPop: _step == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == 2) {
          setState(() => _step = 1);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              if (_step == 2) {
                setState(() => _step = 1);
              } else if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(AppLocalizations.of(context)!.newKegSessionStep(_step)),
        ),
        body: SafeArea(
          child: _step == 1 ? _buildStep1() : _buildStep2(prefs),
        ),
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
            // Beer search
            TextField(
              controller: _beerSearchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: AppLocalizations.of(context)!.searchBeer,
                hintText: AppLocalizations.of(context)!.egKozel,
                suffixIcon: _beerSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _beerSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _beerSearchController.clear();
                              setState(() => _beerSearchResults = []);
                            },
                          )
                        : null,
              ),
              onChanged: _onBeerSearchChanged,
              textInputAction: TextInputAction.search,
            ),
            if (_beerSearchResults.isNotEmpty) ...[
              const SizedBox(height: 4),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: _beerSearchResults.take(7).map((result) {
                    final display = result.breweryName.isNotEmpty
                        ? '${result.name} (${result.breweryName})'
                        : result.name;
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.sports_bar,
                        color: BeerColors.primaryAmber,
                      ),
                      title: Text(display),
                      onTap: () => _selectBeerSearchResult(result),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _beerNameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.beerName,
                hintText: AppLocalizations.of(context)!.egPilsnerUrquell,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterBeerName;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.beerDetailsOptional,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _alcoholController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.alcoholContentPercent,
                hintText: AppLocalizations.of(context)!.egAlcohol,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _breweryController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.brewery,
                hintText: AppLocalizations.of(context)!.egBrewery,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maltController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.malt,
                hintText: AppLocalizations.of(context)!.egMalt,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fermentationController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.fermentation,
                hintText: AppLocalizations.of(context)!.egFermentation,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _beerTypeController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.type,
                hintText: AppLocalizations.of(context)!.egType,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _beerGroupController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.group,
                hintText: AppLocalizations.of(context)!.egGroup,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _beerStyleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.beerStyle,
                hintText: AppLocalizations.of(context)!.egBeerStyle,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _degreePlatoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.degreePlato,
                hintText: AppLocalizations.of(context)!.egDegreePlato,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                if (_formKey1.currentState!.validate()) {
                  setState(() => _step = 2);
                }
              },
              child: Text(AppLocalizations.of(context)!.next),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(FormatPreferences prefs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.kegVolumeLitres,
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
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.orEnterCustomVolume,
                hintText: AppLocalizations.of(context)!.egVolume,
              ),
              validator: (val) {
                if (val == null ||
                    double.tryParse(val.replaceAll(',', '.')) == null) {
                  return AppLocalizations.of(context)!.enterValidNumber;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.kegPriceLabel(_selectedCurrency),
                    ),
                    validator: (val) {
                      if (val == null ||
                          double.tryParse(val.replaceAll(',', '.')) == null) {
                        return AppLocalizations.of(context)!.enterValidNumber;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    items: ['€', '\$', '£', 'Kč']
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCurrency = val);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.predefinedPourSizes,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.tapToRemove,
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
                  label: Text(AppLocalizations.of(context)!.addChip),
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
                    child: Text(AppLocalizations.of(context)!.back),
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
                        : Text(AppLocalizations.of(context)!.createSession),
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

/// Data class for a beer search result from Firestore.
class _BeerSearchResult {
  const _BeerSearchResult({
    required this.name,
    required this.breweryName,
    this.breweryId,
    this.alcoholPercent,
    this.epm,
    this.malt,
    this.fermentation,
    this.type,
    this.group,
    this.beerStyle,
  });

  final String name;
  final String breweryName;
  final String? breweryId;
  final double? alcoholPercent;
  final String? epm;
  final String? malt;
  final String? fermentation;
  final String? type;
  final String? group;
  final String? beerStyle;
}
