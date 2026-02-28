
import os
import re

file_path = r'c:\Users\ashya\Final CITESched Flutter\citesched\citesched_flutter\lib\features\admin\screens\faculty_loading_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update the simple labels (error/loading cases)
content = content.replace(
    "return '${s.program.name.toUpperCase()} ${s.yearLevel}';",
    "return 'BS${s.program.name.toUpperCase()}-${s.sectionCode.split(\"-\").last.split(\" \").last.trim()}';"
)

# 2. Update the data labels with student indicators
# Replace return '${s.program.name.toUpperCase()} ${s.yearLevel}-${s.sectionCode}${isFromStudents ? ' (Students ★)' : ''}';
# with the refined logic.

old_data_label = "return '${s.program.name.toUpperCase()} ${s.yearLevel}-${s.sectionCode}${isFromStudents ? ' (Students ★)' : ''}';"
new_data_label = "return 'BS${s.program.name.toUpperCase()}-${s.sectionCode.split(\"-\").last.split(\" \").last.trim()}${isFromStudents ? ' (Students ★)' : ''}';"

content = content.replace(old_data_label, new_data_label)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("UI refinement 2 complete.")
