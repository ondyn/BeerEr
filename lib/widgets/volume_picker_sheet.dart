import 'package:beerer/theme/beer_theme.dart';
import 'package:beerer/theme/mono_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet with predefined volume chips and a manual stepper.
class VolumePickerSheet extends StatefulWidget {
  const VolumePickerSheet({
    super.key,
    required this.predefinedVolumesMl,
    this.onConfirm,
    this.initialVolumeMl,
    this.title = 'Log a pour for you',
  });

  final List<double> predefinedVolumesMl;
  final Future<void> Function(double volumeMl)? onConfirm;
  final double? initialVolumeMl;
  final String title;

  @override
  State<VolumePickerSheet> createState() => _VolumePickerSheetState();
}

class _VolumePickerSheetState extends State<VolumePickerSheet> {
  late double _selectedVolume;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _selectedVolume = widget.initialVolumeMl ??
        (widget.predefinedVolumesMl.isNotEmpty
            ? widget.predefinedVolumesMl.first
            : 500);
    _controller = TextEditingController(
      text: (_selectedVolume / 1000).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setVolume(double ml) {
    setState(() {
      _selectedVolume = ml;
      _controller.text = (ml / 1000).toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            widget.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // Predefined chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.predefinedVolumesMl.map((ml) {
              final isSelected =
                  (_selectedVolume - ml).abs() < 1;
              return ChoiceChip(
                label: Text('${(ml / 1000).toStringAsFixed(1)}l'),
                selected: isSelected,
                onSelected: (_) => _setVolume(ml),
                selectedColor: BeerColors.primaryAmber,
                labelStyle: TextStyle(
                  color: isSelected
                      ? BeerColors.background
                      : BeerColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Or enter manually:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final newVal =
                      (_selectedVolume - 50).clamp(50.0, 50000.0);
                  _setVolume(newVal);
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: BeerColors.primaryAmber,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  textAlign: TextAlign.center,
                  style: MonoStyle.number(fontSize: 24),
                  decoration: const InputDecoration(
                    suffixText: 'l',
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      setState(() {
                        _selectedVolume = parsed * 1000;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  final newVal =
                      (_selectedVolume + 50).clamp(50.0, 50000.0);
                  _setVolume(newVal);
                },
                icon: const Icon(Icons.add_circle_outline),
                color: BeerColors.primaryAmber,
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop(_selectedVolume);
            },
            icon: const Icon(Icons.check),
            label: const Text('Log Pour'),
          ),
        ],
      ),
    );
  }
}
