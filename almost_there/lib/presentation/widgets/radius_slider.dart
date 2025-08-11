import 'package:flutter/material.dart';

class RadiusSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  const RadiusSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 50.0,
    this.max = 2000.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: _getDivisions(),
          label: _formatValue(value),
          onChanged: onChanged,
        ),
        
        // Preset radius buttons
        Wrap(
          spacing: 8,
          children: _buildPresetButtons(context),
        ),
      ],
    );
  }

  int _getDivisions() {
    // More granular control for smaller values
    if (max <= 1000) {
      return ((max - min) / 25).round();
    }
    return ((max - min) / 50).round();
  }

  String _formatValue(double radius) {
    if (radius >= 1000) {
      return '${(radius / 1000).toStringAsFixed(1)} กม.';
    }
    return '${radius.toInt()} ม.';
  }

  List<Widget> _buildPresetButtons(BuildContext context) {
    final presets = [50.0, 100.0, 200.0, 300.0, 500.0, 1000.0, 1500.0];
    
    return presets.map((preset) {
      final isSelected = (value - preset).abs() < 1;
      
      return FilterChip(
        label: Text(_formatValue(preset)),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            onChanged(preset);
          }
        },
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        checkmarkColor: Theme.of(context).colorScheme.primary,
      );
    }).toList();
  }
}