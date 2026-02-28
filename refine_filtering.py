
import os

file_path = r'c:\Users\ashya\Final CITESched Flutter\citesched\citesched_flutter\lib\features\admin\screens\faculty_loading_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replacement block for the data: (studentSectionCodes) { ... } logic
# This handles the filtering and the new format: BS[Program] - [Section]

new_logic_template = """data: (studentSectionCodes) {
                            final map = \u003cString, int\u003e{};
                            for (final s in sectionList) {
                              // ONLY show if it has active students
                              if (studentSectionCodes.contains(s.sectionCode)) {
                                final label = 'BS${s.program.name.toUpperCase()} - ${s.sectionCode.split("-").last.split(" ").last.trim()}';
                                if (!map.containsKey(label)) {
                                  map[label] = s.id!;
                                }
                              }
                            }
                            return _buildDropdown\u003cint\u003e(
                            label: 'Section',
                            value: %VALUE%,
                            items: map.values.toList(),
                            itemLabel: (id) {
                              final s = sectionList.firstWhere((s) =\u003e s.id == id);
                              return 'BS${s.program.name.toUpperCase()} - ${s.sectionCode.split("-").last.split(" ").last.trim()}';
                            },"""

# Helper to find and replace the block in a modal
def replace_data_block(content, modal_marker, value_text):
    modal_start = content.find(modal_marker)
    if modal_start == -1: return content
    
    data_marker = "data: (studentSectionCodes) {"
    data_idx = content.find(data_marker, modal_start)
    if data_idx == -1: return content
    
    # Find the end of the itemLabel block to replace up to
    # We look for the closing of _buildDropdown
    items_marker = "items: map.values.toList(),"
    items_idx = content.find(items_marker, data_idx)
    if items_idx == -1: return content
    
    # Next is itemLabel
    label_marker = "itemLabel: (id) {"
    label_idx = content.find(label_marker, items_idx)
    if label_idx == -1: return content
    
    # Find the end of itemLabel: (id) { ... }
    # It ends with },
    closing_label_idx = content.find("},", label_idx)
    if closing_label_idx == -1: return content
    
    final_replacement = new_logic_template.replace("%VALUE%", value_text)
    
    # The replacement range is from data_idx up to closing_label_idx + 2
    return content[:data_idx] + final_replacement + content[closing_label_idx + 2:]

# Apply to both modals
content = replace_data_block(content, "class _NewAssignmentModal", "_selectedSectionId")
content = replace_data_block(content, "class _EditAssignmentModal", """sectionList.any(
                                   (s) => s.id == _selectedSectionId,
                                 )
                                 ? _selectedSectionId
                                 : null""")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Filtering and label refinement applied.")
