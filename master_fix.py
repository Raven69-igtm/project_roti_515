import os
import re

lib_path = r'c:\project_roti_515\lib'

def fix_project():
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if not file.endswith('.dart'): continue
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content
            
            # 1. Fix double final/const keywords
            # Examples: 'final List<String> final days', 'final final months'
            new_content = re.sub(r'(final|const)\s+(List<[^>]+>|Map<[^>]+>|String|int|double|bool|dynamic|var)?\s+(final|const)\s+', r'\1 \2 ', new_content)
            # Simplified double keyword
            new_content = re.sub(r'\bfinal\s+final\b', 'final', new_content)
            new_content = re.sub(r'\bconst\s+const\b', 'const', new_content)
            
            # 2. Add missing import for context.colors if used
            if 'context.colors' in new_content:
                if 'app_theme.dart' not in new_content:
                    # Find last import or top of file
                    import_match = list(re.finditer(r'^import\s+.*?;', new_content, re.MULTILINE))
                    if import_match:
                        last_import_pos = import_match[-1].end()
                        new_content = new_content[:last_import_pos] + "\nimport 'package:roti_515/core/theme/app_theme.dart';" + new_content[last_import_pos:]
                    else:
                        new_content = "import 'package:roti_515/core/theme/app_theme.dart';\n" + new_content

            # 3. Fix missing 'final' for top-level or local variables that were stripped of 'const'
            # This is hard to do safely globally, but let's target specific common ones
            for var_name in ['messages', 'icons', 'months', 'days']:
                new_content = re.sub(rf'^(?!\s*final|const|var|static|Widget|dynamic)\s*\b{var_name}\b\s*=', rf'  final {var_name} =', new_content, flags=re.MULTILINE)

            if content != new_content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)

if __name__ == "__main__":
    fix_project()
    print("Master fix complete.")
