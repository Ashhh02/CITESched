
import os

file_path = r'c:\Users\ashya\Final CITESched Flutter\citesched\citesched_flutter\lib\features\admin\screens\faculty_loading_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the specific syntax error ),} -> ); }
# The compiler expects return _buildDropdown(...); }
content = content.replace("),}", "); }")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Syntax fix applied.")
