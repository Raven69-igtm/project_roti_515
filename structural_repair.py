import os
import re

lib_path = r'c:\project_roti_515\lib'

def fix_structural_errors():
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if not file.endswith('.dart'): continue
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content
            
            # 1. Fix MainBottomNavBar specifically
            if 'class MainBottomNavBar' in new_content:
                new_content = new_content.replace('_buildNavItem(Icons.', '_buildNavItem(context, Icons.')
                new_content = new_content.replace('Widget _buildNavItem(IconData iconOutline', 'Widget _buildNavItem(BuildContext context, IconData iconOutline')

            # 2. Fix PremiumSnackbar calls: showSuccess("msg") -> showSuccess(context, "msg")
            # If it's called with only one string argument
            new_content = re.sub(r'PremiumSnackbar\.(showSuccess|showError|showInfo)\(\s*"', r'PremiumSnackbar.\1(context, "', new_content)
            # If it's called with one variable argument that doesn't look like context
            # (Very rough, but often correct)
            # new_content = re.sub(r'PremiumSnackbar\.(showSuccess|showError|showInfo)\((?!context|null)', r'PremiumSnackbar.\1(context, ', new_content)

            # 3. Fix duplicate context in product_admin_screen.dart
            if 'product_admin_screen.dart' in filepath:
                new_content = new_content.replace('BuildContext context, BuildContext context, BuildContext context', 'BuildContext context')
                new_content = new_content.replace('BuildContext context, BuildContext context', 'BuildContext context')
                # Calls
                new_content = new_content.replace('(context, context, context, context', '(context')
                new_content = new_content.replace('(context, context, context', '(context')
                new_content = new_content.replace('(context, context', '(context')

            # 4. Fix popUntil calls with incorrect number of arguments
            # error - 2 positional arguments expected by 'popUntil', but 1 found - lib\features\profile\widgets\profile_logout_button.dart:26:58
            new_content = re.sub(r'Navigator\.popUntil\((context,?\s*)?(\(.*?\) => .*?)\)', r'Navigator.popUntil(context, \2)', new_content)

            # 5. Fix checkout_styles.dart missing declaration
            if 'checkout_styles.dart' in filepath:
                new_content = re.sub(r'^(\s*)(\w+)\s*=\s*', r'\1final \2 = ', new_content, flags=re.MULTILINE)

            if content != new_content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)

if __name__ == "__main__":
    fix_structural_errors()
    print("Structural repair complete.")
