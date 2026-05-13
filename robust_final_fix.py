import os
import re

lib_path = r'c:\project_roti_515\lib'

def robust_fix():
    # 1. order_admin_screen.dart
    path = os.path.join(lib_path, 'features', 'admin', 'orders', 'screens', 'order_admin_screen.dart')
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        # _buildPickupTimeSection(anyVar) -> _buildPickupTimeSection(context, anyVar)
        content = re.sub(r'_buildPickupTimeSection\((?![context])(\w+)\)', r'_buildPickupTimeSection(context, \1)', content)
        # _buildItemRow(anyVar) -> _buildItemRow(context, anyVar)
        content = re.sub(r'_buildItemRow\((?![context])(\w+)\)', r'_buildItemRow(context, \1)', content)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

    # 2. Add context to _showAddedSnackBar calls project-wide
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if not file.endswith('.dart'): continue
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content
            # _showAddedSnackBar(name) -> _showAddedSnackBar(context, name)
            new_content = re.sub(r'_showAddedSnackBar\((?![context])(.*?)\)', r'_showAddedSnackBar(context, \1)', new_content)
            # Fix definition if it was modified incorrectly
            new_content = new_content.replace('Widget _showAddedSnackBar(String message)', 'Widget _showAddedSnackBar(BuildContext context, String message)')
            
            if content != new_content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)

if __name__ == "__main__":
    robust_fix()
    print("Robust final fix complete.")
