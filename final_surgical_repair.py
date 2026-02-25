import os
import re

lib_path = r'c:\project_roti_515\lib'

def final_surgical_repair():
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if not file.endswith('.dart'): continue
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content
            
            # 1. Fix Navigator.pop(context, ctx, result) -> Navigator.pop(context, result)
            new_content = re.sub(r'Navigator\.pop\(context,\s*ctx,\s*', r'Navigator.pop(context, ', new_content)
            
            # 2. Fix PremiumSnackbar calls properly
            # PremiumSnackbar.showSuccess(context, "msg") is correct.
            # If it was PremiumSnackbar.showSuccess("msg"), it needs context.
            # But wait, my previous script added context.
            # Let's check for double context: PremiumSnackbar.showSuccess(context, context, "msg")
            new_content = re.sub(r'PremiumSnackbar\.(showSuccess|showError|showInfo)\(context,\s*context,\s*', r'PremiumSnackbar.\1(context, ', new_content)

            # 3. Fix _buildActionButton signature in product_admin_screen.dart
            if 'product_admin_screen.dart' in filepath:
                new_content = re.sub(r'Widget _buildActionButton\(BuildContext context,.*?\s+IconData icon', r'Widget _buildActionButton(BuildContext context, IconData icon', new_content)

            # 4. Fix _showAddedSnackBar calls in favorite_card.dart etc.
            # Definition: Widget _showAddedSnackBar(BuildContext context, String message)
            # Call: _showAddedSnackBar("msg") -> _showAddedSnackBar(context, "msg")
            new_content = re.sub(r'_showAddedSnackBar\(\s*"', r'_showAddedSnackBar(context, "', new_content)

            # 5. Fix showSuccess calls in bestseller_card.dart etc.
            new_content = re.sub(r'PremiumSnackbar\.showSuccess\(\s*"', r'PremiumSnackbar.showSuccess(context, "', new_content)

            # 6. Fix sortMap undefined in home_filter_sheet.dart
            if 'home_filter_sheet.dart' in filepath:
                if 'final sortMap =' not in new_content and 'sortMap =' in new_content:
                    new_content = new_content.replace('sortMap =', 'final sortMap =')

            if content != new_content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)

if __name__ == "__main__":
    final_surgical_repair()
    print("Final surgical repair complete.")
