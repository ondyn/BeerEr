import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BeerEditScreen extends StatefulWidget {
  const BeerEditScreen({super.key, this.docId, this.data});

  final String? docId;
  final Map<String, dynamic>? data;

  @override
  State<BeerEditScreen> createState() => _BeerEditScreenState();
}

class _BeerEditScreenState extends State<BeerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _breweryName;
  late final TextEditingController _breweryId;
  late final TextEditingController _epm;
  late final TextEditingController _alcohol;
  late final TextEditingController _malt;
  late final TextEditingController _fermentation;
  late final TextEditingController _type;
  late final TextEditingController _group;
  late final TextEditingController _beerStyle;
  bool _isSaving = false;

  bool get _isEditing => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.data ?? {};
    _name = TextEditingController(text: d['name'] as String? ?? '');
    _breweryName = TextEditingController(text: d['brewery_name'] as String? ?? '');
    _breweryId = TextEditingController(text: d['brewery_id'] as String? ?? '');
    _epm = TextEditingController(text: d['epm'] as String? ?? '');
    _alcohol = TextEditingController(
      text: d['alcohol_percent'] != null ? d['alcohol_percent'].toString() : '',
    );
    _malt = TextEditingController(text: d['malt'] as String? ?? '');
    _fermentation = TextEditingController(text: d['fermentation'] as String? ?? '');
    _type = TextEditingController(text: d['type'] as String? ?? '');
    _group = TextEditingController(text: d['group'] as String? ?? '');
    _beerStyle = TextEditingController(text: d['beer_style'] as String? ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _breweryName.dispose();
    _breweryId.dispose();
    _epm.dispose();
    _alcohol.dispose();
    _malt.dispose();
    _fermentation.dispose();
    _type.dispose();
    _group.dispose();
    _beerStyle.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final doc = <String, dynamic>{
        'name': _name.text.trim(),
        'name_lower': _name.text.trim().toLowerCase(),
        'brewery_name': _breweryName.text.trim(),
        'brewery_id': _breweryId.text.trim(),
        if (_epm.text.trim().isNotEmpty) 'epm': _epm.text.trim(),
        if (_alcohol.text.trim().isNotEmpty)
          'alcohol_percent': double.tryParse(_alcohol.text.trim()),
        if (_malt.text.trim().isNotEmpty) 'malt': _malt.text.trim(),
        if (_fermentation.text.trim().isNotEmpty)
          'fermentation': _fermentation.text.trim(),
        if (_type.text.trim().isNotEmpty) 'type': _type.text.trim(),
        if (_group.text.trim().isNotEmpty) 'group': _group.text.trim(),
        if (_beerStyle.text.trim().isNotEmpty)
          'beer_style': _beerStyle.text.trim(),
        'source': 'manual',
      };

      final db = FirebaseFirestore.instance;
      if (_isEditing) {
        await db.collection('beers').doc(widget.docId).update(doc);
      } else {
        await db.collection('beers').doc().set(doc);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Beer' : 'Add Beer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Beer Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _breweryName,
                decoration: const InputDecoration(labelText: 'Brewery Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _breweryId,
                decoration: const InputDecoration(
                  labelText: 'Brewery ID (Firestore doc ID)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _alcohol,
                decoration: const InputDecoration(
                  labelText: 'Alcohol %',
                  hintText: 'e.g. 4.6',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _epm,
                decoration: const InputDecoration(
                  labelText: 'EPM (degrees Plato)',
                  hintText: 'e.g. 12°',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _malt,
                decoration: const InputDecoration(labelText: 'Malt'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fermentation,
                decoration: const InputDecoration(labelText: 'Fermentation'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _type,
                decoration: const InputDecoration(
                  labelText: 'Type (světlé/tmavé/...)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _group,
                decoration: const InputDecoration(
                  labelText: 'Group (ležák/výčepní/...)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _beerStyle,
                decoration: const InputDecoration(
                  labelText: 'Beer Style (IPA, Lager, ...)',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Update' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
