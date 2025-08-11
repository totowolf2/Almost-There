import 'package:flutter/material.dart';

class DaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onSelectionChanged;

  const DaySelector({
    super.key,
    required this.selectedDays,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    const dayNames = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];
    const dayColors = [
      Colors.red, // Sunday
      Colors.amber, // Monday
      Colors.pink, // Tuesday
      Colors.green, // Wednesday
      Colors.orange, // Thursday
      Colors.blue, // Friday
      Colors.purple, // Saturday
    ];

    return Column(
      children: [
        // Day selection buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final isSelected = selectedDays.contains(index);

            return GestureDetector(
              onTap: () => _toggleDay(index),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? dayColors[index]
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(color: dayColors[index], width: 2),
                ),
                child: Center(
                  child: Text(
                    dayNames[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : dayColors[index],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        // Quick selection buttons
        Wrap(
          spacing: 8,
          children: [
            _buildQuickSelectChip(context, 'ทุกวัน', [0, 1, 2, 3, 4, 5, 6]),
            _buildQuickSelectChip(context, 'จ-ส', [1, 2, 3, 4, 5, 6]),
            _buildQuickSelectChip(context, 'จ-ศ', [1, 2, 3, 4, 5]),
            _buildQuickSelectChip(context, 'เสาร์-อาทิตย์', [0, 6]),
            _buildQuickSelectChip(context, 'ล้างทั้งหมด', []),
          ],
        ),

        const SizedBox(height: 8),

        // Selected days summary
        if (selectedDays.isNotEmpty) ...[
          Text(
            'เลือก: ${_getSelectedDaysText()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ] else ...[
          Text(
            'ไม่ได้เลือกวันใด',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ],
    );
  }

  void _toggleDay(int day) {
    final newSelection = List<int>.from(selectedDays);

    if (newSelection.contains(day)) {
      newSelection.remove(day);
    } else {
      newSelection.add(day);
    }

    newSelection.sort();
    onSelectionChanged(newSelection);
  }

  Widget _buildQuickSelectChip(
    BuildContext context,
    String label,
    List<int> days,
  ) {
    final isCurrentSelection = _listEquals(selectedDays, days);

    return ActionChip(
      label: Text(label),
      onPressed: () => onSelectionChanged(days),
      backgroundColor: isCurrentSelection
          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
          : null,
      side: isCurrentSelection
          ? BorderSide(color: Theme.of(context).colorScheme.primary)
          : null,
    );
  }

  String _getSelectedDaysText() {
    if (selectedDays.isEmpty) return 'ไม่ได้เลือกวันใด';

    const dayNames = [
      'อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์',
    ];
    final sortedDays = [...selectedDays]..sort();

    if (sortedDays.length == 7) return 'ทุกวัน';
    if (sortedDays.length == 5 &&
        sortedDays.every((day) => day >= 1 && day <= 5)) {
      return 'วันทำงาน';
    }
    if (sortedDays.length == 2 &&
        sortedDays.contains(0) &&
        sortedDays.contains(6)) {
      return 'สุดสัปดาห์';
    }

    return sortedDays.map((day) => dayNames[day]).join(', ');
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sortedA = [...a]..sort();
    final sortedB = [...b]..sort();
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }
}
