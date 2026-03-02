import os
import re

lib_path = r'c:\project_roti_515\lib'

def fix_last_errors():
    # 1. order_admin_screen.dart
    path = os.path.join(lib_path, 'features', 'admin', 'orders', 'screens', 'order_admin_screen.dart')
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        content = content.replace('_buildPickupTimeSection(order)', '_buildPickupTimeSection(context, order)')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

    # 2. add_product_screen.dart
    path = os.path.join(lib_path, 'features', 'admin', 'product_admin', 'screens', 'add_product_screen.dart')
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        content = content.replace('_buildAppBar(context)', '_buildAppBar()')
        content = content.replace('Widget _buildAppBar(BuildContext context)', 'Widget _buildAppBar()')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

    # 3. snackbar calls with missing context
    for f_name in [
        os.path.join('features', 'favorite', 'widgets', 'favorite_card.dart'),
        os.path.join('features', 'home', 'widgets', 'bestseller_card.dart'),
        os.path.join('features', 'home', 'widgets', 'new_menu_card.dart')
    ]:
        path = os.path.join(lib_path, f_name)
        if os.path.exists(path):
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            content = content.replace('_showAddedSnackBar(food.name)', '_showAddedSnackBar(context, food.name)')
            content = content.replace('_showAddedSnackBar(name)', '_showAddedSnackBar(context, name)')
            # and definition
            content = content.replace('Widget _showAddedSnackBar(String message)', 'Widget _showAddedSnackBar(BuildContext context, String message)')
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)

    # 4. notification_screen.dart
    path = os.path.join(lib_path, 'features', 'notification', 'screens', 'notification_screen.dart')
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        # _buildNotificationItem(context, notification, provider, index) -> _buildNotificationItem(context, notification, index)
        content = re.sub(r'_buildNotificationItem\((context,\s*notification),\s*provider,\s*index\)', r'_buildNotificationItem(\1, index)', content)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

    # 5. order_detail_page.dart
    path = os.path.join(lib_path, 'presentation', 'pages', 'profile', 'order_detail_page.dart')
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        content = content.replace('_buildAppBar(context)', '_buildAppBar()')
        content = content.replace('PreferredSizeWidget _buildAppBar()', 'PreferredSizeWidget _buildAppBar(BuildContext context)') # Wait, if call has 1 arg but definition has 0...
        # Error said: Too many positional arguments: 0 expected, but 1 found
        # So call had 1 (context) but definition had 0.
        # Let's add context to definition.
        # But it also said: Undefined name 'context' - line 82.
        # So I should probably add context to definition AND use it.
        content = content.replace('PreferredSizeWidget _buildAppBar()', 'PreferredSizeWidget _buildAppBar(BuildContext context)')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

if __name__ == "__main__":
    fix_last_errors()
    print("Final targeted fix complete.")
