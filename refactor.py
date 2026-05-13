import os
import re

app_theme_import = "import 'package:roti_515/core/theme/app_theme.dart';\n"

for root, dirs, files in os.walk(r'c:\project_roti_515\lib'):
    for file in files:
        if file.endswith('.dart') and file != 'app_colors.dart' and file != 'app_theme.dart':
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if 'AppColors.' in content:
                # Add import if not present
                if 'core/theme/app_theme.dart' not in content:
                    # Find last import
                    import_idx = content.rfind('import ')
                    if import_idx != -1:
                        end_of_import = content.find('\n', import_idx)
                        content = content[:end_of_import+1] + app_theme_import + content[end_of_import+1:]
                    else:
                        content = app_theme_import + content
                
                # Replace AppColors.xyz with context.colors.xyz
                content = re.sub(r'AppColors\.([a-zA-Z0-9_]+)', r'context.colors.\1', content)
                
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
print("Refactoring complete.")
