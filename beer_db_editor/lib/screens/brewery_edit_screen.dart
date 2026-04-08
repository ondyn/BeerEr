import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BreweryEditScreen extends StatefulWidget {
  const BreweryEditScreen({super.key, this.docId, this.data});

  final String? docId;
  final Map<String, dynamic>? data;

  @override
  State<BreweryEditScreen> createState() => _BreweryEditScreenState();
}

class _BreweryEditScreenState extends State<BreweryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _website;
  late final TextEditingController _yearFounded;
  late final TextEditingController _region;
  bool _isSaving = false;

  bool get _isEditing => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.data ?? {};
    _name = TextEditingController(text: d['name'] as String? ?? '');
    _address = TextEditingController(text: d['address'] as String? ?? '');
    _website = TextEditingController(text: d['website'] as String? ?? '');
    _yearFounded =
        TextEditingController(text: d['year_founded'] as String? ?? '');
    _region = TextEditingController(text: d['region'] as String? ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _website.dispose();
    _yearFounded.dispose();
    _region.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final doc = <String, dynamic>{
        'name': _name.text.trim(),
        'name_lower': _name.text.trim().toLowerCase(),
        if (_address.text.trim().isNotEmpty) 'address': _address.text.trim(),
        if (_website.text.trim().isNotEmpty) 'website': _website.text.trim(),
        if (_yearFounded.text.trim().isNotEmpty)
          'year_founded': _yearFounded.text.trim(),
        if (_region.text.trim().isNotEmpty) 'region': _region.text.trim(),
        'source': 'manual',
      };

      final db = FirebaseFirestore.instance;
      if (_isEditing) {
        await db.collection('breweries').doc(widget.docId).update(doc);
      } else {
        await db.collection('breweries').doc().set(doc);
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
        title: Text(_isEditing ? 'Edit Brewery' : 'Add Brewery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Brewery Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _website,
                decoration: const InputDecoration(labelText: 'Website'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearFounded,
                decoration: const InputDecoration(labelText: 'Year Founded'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _region,
                decoration: const InputDecoration(labelText: 'Region'),
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
