import re

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    helper_code = '''
  void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;
    String cleanMessage = message.replaceAll('Exception: ', '').trim();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text('Action Failed',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
          ],
        ),
        content: Text(cleanMessage,
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
'''
    classes = ['_AddFacultyModalState', '_EditFacultyModalState', '_AddRoomModalState', '_EditRoomModalState', '_AddSubjectModalState', '_EditSubjectModalState']
    
    for cls in classes:
        # Avoid double inject if we previously ran powershell
        if helper_code.strip()[:30] in content and cls == '_AddFacultyModalState':
            continue
            
        class_pattern = re.compile(r'(class ' + cls + r' extends State<[^>]+> \{)')
        if class_pattern.search(content) and '_showErrorDialog' not in content.split('class ' + cls)[1].split('Widget build(')[0]:
             content = class_pattern.sub(r'\1\n' + helper_code, content)
             print(f'Injecting into {cls} in {file_path}')

    # catch replacements
    # 1. AddFaculty
    content = re.sub(r'\} catch \(e\) \{\s*if \(mounted\) \{\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(''Error: \$e''\),\s*backgroundColor: Colors\.red,\s*\),\s*\);\s*\}\s*\} finally',
    r'''} catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    } finally''', content)
    
    # 2. EditFaculty (single line snackbar)
    content = re.sub(r'\} catch \(e\) \{\s*if \(mounted\) \{\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(content: Text\(''Error: \$e''\), backgroundColor: Colors\.red\),\s*\);\s*\}\s*\} finally',
    r'''} catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    } finally''', content)

    # 3. Room 
    content = re.sub(r'\} catch \(e\) \{\s*if \(mounted\)\s*ScaffoldMessenger\.of\(\s*context,\s*\)\.showSnackBar\(SnackBar\(content: Text\(''Error: \$e''\)\)\);\s*\} finally',
    r'''} catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    } finally''', content)

    # 4. Subject
    content = re.sub(r'\} catch \(e\) \{\s*if \(mounted\) \{\s*ScaffoldMessenger\.of\(\s*context,\s*\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(''(?:Failed to create subject|Failed to update subject): \$e''\),\s*backgroundColor: Colors\.red,\s*\),\s*\);\s*\}\s*\} finally',
    r'''} catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    } finally''', content)


    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

process_file('c:/Users/ashya/Final CITESched Flutter/citesched/citesched_flutter/lib/features/admin/screens/faculty_management_screen.dart')
process_file('c:/Users/ashya/Final CITESched Flutter/citesched/citesched_flutter/lib/features/admin/screens/room_management_screen.dart')
process_file('c:/Users/ashya/Final CITESched Flutter/citesched/citesched_flutter/lib/features/admin/screens/subject_management_screen.dart')
