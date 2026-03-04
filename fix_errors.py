import os
import re

def fix_const_and_context():
    lib_path = r'c:\project_roti_515\lib'
    
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if not file.endswith('.dart'):
                continue
            
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            new_lines = []
            changed = False
            
            # Phase 1: Fix Undefined context in helper methods for common widgets
            # If a method uses context.colors but doesn't have context in params, try to add it.
            # This is a bit risky but we can target specific patterns.
            
            content = "".join(lines)
            
            # Simple fix for helper methods in MainBottomNavBar and similar
            # Find Widget _methodName(...) { ... context.colors ... }
            def add_context_to_method(match):
                method_header = match.group(1)
                params = match.group(2)
                body = match.group(3)
                if 'context.colors' in body and 'BuildContext context' not in params:
                    new_params = 'BuildContext context, ' + params if params else 'BuildContext context'
                    return f"Widget {method_header}({new_params}) {body}"
                return match.group(0)

            # Target common helper method patterns
            content = re.sub(r'Widget\s+([_a-zA-Z0-9]+)\s*\(([^)]*)\)\s*(\{.*?context\.colors.*?\})', 
                            add_context_to_method, content, flags=re.DOTALL)
            
            # Also need to update calls to these methods if we changed them.
            # This is harder. Let's focus on const removal first as it's the majority of errors.
            
            lines = content.splitlines(keepends=True)
            
            for i in range(len(lines)):
                line = lines[i]
                
                # Rule 1: Remove const from current line if it contains context.colors
                if 'const ' in line and 'context.colors' in line:
                    line = line.replace('const ', '')
                    changed = True
                
                # Rule 2: Remove const from previous line if current line has context.colors and looks like a property
                if i > 0 and 'context.colors' in line:
                    prev_line = lines[i-1]
                    if 'const ' in prev_line:
                        # Check if current line is a property assignment
                        if re.search(r'^\s*[a-zA-Z]+\s*:', line):
                            lines[i-1] = prev_line.replace('const ', '')
                            changed = True
                
                new_lines.append(line)
            
            if changed or content != "".join(new_lines):
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.writelines(new_lines)

# Specific fix for MainBottomNavBar calls
def fix_main_nav_bar():
    path = r'c:\project_roti_515\lib\features\main_nav\widgets\main_bottom_nav_bar.dart'
    if not os.path.exists(path): return
    
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Add context to _buildNavItem calls
    content = content.replace('_buildNavItem(', '_buildNavItem(context, ')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

fix_const_and_context()
fix_main_nav_bar()
print("Fixing complete.")
