
import os

file_path = r'c:\Users\ashya\Final CITESched Flutter\citesched\citesched_flutter\lib\features\admin\screens\faculty_loading_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

def process_modal(content, modal_name):
    # Find the modal class
    modal_start = content.find(modal_name)
    if modal_start == -1:
        return content
    
    # Find the data block within this modal
    data_marker = "data: (studentSectionCodes) => _buildDropdown<int>("
    data_idx = content.find(data_marker, modal_start)
    if data_idx == -1:
        return content
    
    # The replacement for the beginning of the block
    new_data_start = """data: (studentSectionCodes) {
                            final map = <String, int>{};
                            for (final s in sectionList) {
                              final label = 'BS${s.program.name.toUpperCase()}-${s.sectionCode.split("-").last.split(" ").last.trim()}';
                              if (!map.containsKey(label) || studentSectionCodes.contains(s.sectionCode)) {
                                map[label] = s.id!;
                              }
                            }
                            return _buildDropdown<int>("""
    
    # We replace the start
    content = content[:data_idx] + new_data_start + content[data_idx + len(data_marker):]
    
    # Now we need to find the specific items: line AFTER this data_idx
    items_marker = "items: sectionList.map((s) => s.id!).toList(),"
    items_idx = content.find(items_marker, data_idx)
    if items_idx != -1:
        content = content[:items_idx] + "items: map.values.toList()," + content[items_idx + len(items_marker):]
    
    # Finally, we need to add the closing brace for the data block.
    # The _buildDropdown is usually followed by a few arguments and then a closing ),
    # We look for the next ), that is preceded by a validator or similar.
    # A safer way might be to look for the next validator and then the next ),
    
    validator_idx = content.find("validator:", data_idx)
    if validator_idx != -1:
        # Find the next ),
        closing_idx = content.find("),", validator_idx)
        if closing_idx != -1:
            content = content[:closing_idx + 2] + "}" + content[closing_idx + 2:]
            
    return content

content = process_modal(content, "class _NewAssignmentModal")
content = process_modal(content, "class _EditAssignmentModal")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Deduplication logic injected correctly.")
