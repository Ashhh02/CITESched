import os
import re

directory = r'c:\Users\ashya\Final CITESched Flutter\citesched\citesched_flutter\lib\features\admin\screens'

# Matches ScaffoldMessenger that contains Colors.red
pattern = re.compile(r'ScaffoldMessenger\.of\([^;]+backgroundColor:\s*Colors\.red[^;]*\);', re.DOTALL)

updated_files = 0
for root, _, files in os.walk(directory):
    for filename in files:
        if filename.endswith('.dart'):
            filepath = os.path.join(root, filename)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
            if pattern.search(content):
                content = pattern.sub('AppErrorDialog.show(context, e);', content)
                
                # Insert import right after the first line (or other imports)
                import_stmt = "import 'package:citesched_flutter/core/utils/error_handler.dart';"
                if import_stmt not in content:
                    # Find last import
                    import_idx = content.rfind('import \'')
                    if import_idx != -1:
                        end_of_line = content.find('\n', import_idx)
                        content = content[:end_of_line+1] + import_stmt + '\n' + content[end_of_line+1:]
                    else:
                        content = import_stmt + '\n' + content
                        
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Updated {filename}")
                updated_files += 1

print(f"Total files updated: {updated_files}")
