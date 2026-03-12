import 'package:citesched_client/citesched_client.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimetableFilterPanel extends StatelessWidget {
  final TimetableFilterRequest currentFilter;
  final Function(TimetableFilterRequest) onFilterChanged;
  final List<Faculty> facultyList;
  final List<Room> roomList;

  const TimetableFilterPanel({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.facultyList,
    required this.roomList,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          // Program Filter
          _buildFilterDropdown<Program>(
            label: 'Program',
            value: currentFilter.program,
            items: Program.values,
            itemLabel: (v) => v.toString().split('.').last.toUpperCase(),
            onChanged: (v) =>
                onFilterChanged(currentFilter.copyWith(program: v)),
          ),
          const SizedBox(height: 12),
          // Section Filter
          TextField(
            decoration: InputDecoration(
              labelText: 'Section',
              labelStyle: GoogleFonts.poppins(fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: (v) => onFilterChanged(
              currentFilter.copyWith(section: v.isEmpty ? null : v),
            ),
          ),
          const SizedBox(height: 12),
          // Year Level Filter
          _buildFilterDropdown<int>(
            label: 'Year Level',
            value: currentFilter.yearLevel,
            items: [1, 2, 3, 4],
            itemLabel: (v) => 'Year $v',
            onChanged: (v) =>
                onFilterChanged(currentFilter.copyWith(yearLevel: v)),
          ),
          const SizedBox(height: 12),
          // Faculty Filter
          _buildFilterDropdown<int>(
            label: 'Faculty',
            value: currentFilter.facultyId,
            items: facultyList.map((f) => f.id!).toList(),
            itemLabel: (id) => facultyList.firstWhere((f) => f.id == id).name,
            onChanged: (v) =>
                onFilterChanged(currentFilter.copyWith(facultyId: v)),
          ),
          const SizedBox(height: 12),
          // Room Filter
          _buildFilterDropdown<int>(
            label: 'Room',
            value: currentFilter.roomId,
            items: roomList.map((r) => r.id!).toList(),
            itemLabel: (id) => roomList.firstWhere((r) => r.id == id).name,
            onChanged: (v) =>
                onFilterChanged(currentFilter.copyWith(roomId: v)),
          ),
          const SizedBox(height: 12),
          // Conflict Filter
          SwitchListTile(
            title: Text(
              'Only Conflicts',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            value: currentFilter.hasConflicts ?? false,
            onChanged: (v) =>
                onFilterChanged(currentFilter.copyWith(hasConflicts: v)),
            contentPadding: EdgeInsets.zero,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => onFilterChanged(TimetableFilterRequest()),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87,
            ),
            child: Text('Reset Filters', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text('All $label', style: GoogleFonts.poppins(fontSize: 14)),
        ),
        ...items.map(
          (item) => DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemLabel(item),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
