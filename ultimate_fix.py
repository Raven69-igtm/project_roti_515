import os
import re

lib_path = r'c:\project_roti_515\lib'

def ultimate_fix():
    # 1. add_product_screen.dart
    path = os.path.join(lib_path, 'features', 'admin', 'product_admin', 'screens', 'add_product_screen.dart')
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        content = re.sub(r'_buildAppBar\(context\)', '_buildAppBar()', content)
        content = re.sub(r'Widget _buildAppBar\(BuildContext context\)', 'Widget _buildAppBar()', content)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

    # 2. notification_screen.dart
    path = os.path.join(lib_path, 'features', 'notification', 'screens', 'notification_screen.dart')
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        content = content.replace('_buildNotificationItem(context, notification, provider, index)', '_buildNotificationItem(context, notification, index)')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

    # 3. Clean up double context in signatures and calls project-wide
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if not file.endswith('.dart'): continue
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content
            # Signatures
            new_content = new_content.replace('BuildContext context, context,', 'BuildContext context,')
            new_content = new_content.replace('BuildContext context, context', 'BuildContext context')
            # Calls
            new_content = new_content.replace('(context, context,', '(context,')
            new_content = new_content.replace('(context, context)', '(context)')
            
            if content != new_content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)

if __name__ == "__main__":
    ultimate_fix()
    print("Ultimate fix complete.")
