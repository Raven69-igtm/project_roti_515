import os
import re

lib_path = r'c:\project_roti_515\lib'

def fix_const_in_files():
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if not file.endswith('.dart'):
                continue
            
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            new_lines = list(lines)
            changed = False
            
            for i in range(len(lines)):
                if 'context.colors' in lines[i]:
                    # Search backwards up to 10 lines for the 'const' that might be causing the error
                    for j in range(i, max(-1, i-10), -1):
                        if 'const ' in new_lines[j]:
                            # Heuristic: if the const line starts a widget or object
                            if re.search(r'const\s+[A-Z_]', new_lines[j]) or 'const [' in new_lines[j]:
                                new_lines[j] = new_lines[j].replace('const ', '')
                                changed = True
            
            if changed:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.writelines(new_lines)

# Fix common helper methods in specific files
def fix_known_context_errors():
    files_to_fix = [
        r'c:\project_roti_515\lib\features\main_nav\widgets\main_bottom_nav_bar.dart',
        r'c:\project_roti_515\lib\features\admin\users\screens\user_admin_screen.dart',
        r'c:\project_roti_515\lib\features\admin\product_admin\screens\product_admin_screen.dart',
        r'c:\project_roti_515\lib\features\admin\orders\screens\order_admin_screen.dart',
    ]
    
    for path in files_to_fix:
        if not os.path.exists(path): continue
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 1. Ensure build methods have context (recovery from previous bad regex)
        content = re.sub(r'Widget\s+build\s*\(\)', r'Widget build(BuildContext context)', content)
        
        # 2. Add context to helper method definitions and calls
        # Target: Widget _buildSomething(Params) { ... context.colors ... }
        # This is a bit specific but targets the problem areas
        
        # Helper for _buildNavItem in BottomNavBar
        if 'MainBottomNavBar' in content:
            content = content.replace('_buildNavItem(', '_buildNavItem(context, ')
            content = content.replace('Widget _buildNavItem(context, ', 'Widget _buildNavItem(BuildContext context, ')

        # General helper method context passing (aggressive)
        # Search for helper methods that use context.colors but don't have BuildContext context
        def helper_fix(match):
            name = match.group(1)
            params = match.group(2)
            body = match.group(3)
            if 'context.colors' in body and 'BuildContext context' not in params:
                new_params = 'BuildContext context, ' + params if params else 'BuildContext context'
                return f"Widget {name}({new_params}) {body}"
            return match.group(0)

        content = re.sub(r'Widget\s+([_a-zA-Z0-9]+)\s*\(([^)]*)\)\s*(\{.*?context\.colors.*?\})', 
                        helper_fix, content, flags=re.DOTALL)
        
        # Try to fix calls to these methods by adding context
        # This is the riskiest part. We only do it for known problematic methods.
        methods_to_fix_calls = ['_buildTabItem', '_buildNavItem', '_buildStatusBadge', '_buildProductCard', '_buildInfoRow', '_buildSection']
        for m in methods_to_fix_calls:
            # Replace method(arg1, ...) with method(context, arg1, ...)
            # but only if not already having context
            content = re.sub(rf'({m})\((?!context,)(?!context\))', r'\1(context, ', content)

        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

fix_const_in_files()
fix_known_context_errors()
print("Surgical fix complete.")
