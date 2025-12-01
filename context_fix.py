import os
import re

def fix_undefined_context(log_file):
    content = ""
    for enc in ['utf-16', 'utf-8', 'latin-1']:
        try:
            with open(log_file, 'r', encoding=enc) as f:
                content = f.read()
            if "error" in content: break
        except: continue
    
    if not content: return

    # Match: error - Undefined name 'context' - filepath:line:col - undefined_identifier
    pattern = r"error - Undefined name 'context' - (.*?):(\d+):(\d+) - undefined_identifier"
    matches = re.findall(pattern, content)
    print(f"Found {len(matches)} undefined context errors")
    
    # Process file by file
    files_to_errors = {}
    for filepath, line, col in matches:
        if filepath not in files_to_errors: files_to_errors[filepath] = []
        files_to_errors[filepath].append(int(line))

    for filepath in files_to_errors:
        full_path = os.path.join(r'c:\project_roti_515', filepath)
        if not os.path.exists(full_path): continue
        
        with open(full_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        content = "".join(lines)
        changed = False
        
        # For each error line, find the method definition it's in
        error_lines = sorted(list(set(files_to_errors[filepath])))
        
        methods_to_fix = set()
        
        for line_num in error_lines:
            # Search backwards for method definition: Widget name(...) { or PreferredSizeWidget name(...) {
            for i in range(line_num - 1, max(-1, line_num - 50), -1):
                m = re.search(r'(Widget|PreferredSizeWidget|List<Widget>|dynamic)\s+([_a-zA-Z0-9]+)\s*\(([^)]*)\)\s*\{', lines[i])
                if m:
                    ret_type = m.group(1)
                    method_name = m.group(2)
                    params = m.group(3)
                    if 'BuildContext context' not in params:
                        methods_to_fix.add(method_name)
                    break
        
        if methods_to_fix:
            print(f"Fixing methods in {filepath}: {methods_to_fix}")
            for method_name in methods_to_fix:
                # 1. Update definition
                # We need to be careful with regex to not match other things
                def add_context_def(match):
                    ret_type = match.group(1)
                    name = match.group(2)
                    params = match.group(3)
                    if 'BuildContext context' in params: return match.group(0)
                    new_params = 'BuildContext context, ' + params if params else 'BuildContext context'
                    return f"{ret_type} {name}({new_params}) {{"

                content = re.sub(rf'(Widget|PreferredSizeWidget|List<Widget>|dynamic)\s+({method_name})\s*\(([^)]*)\)\s*\{{', 
                                add_context_def, content)
                
                # 2. Update calls
                # Match method(arg1, arg2) but not definition
                # Avoid matching method definition by ensuring it doesn't end with {
                def add_context_call(match):
                    name = match.group(1)
                    args = match.group(2)
                    if args.strip().startswith('context'): return match.group(0)
                    new_args = 'context, ' + args if args.strip() else 'context'
                    return f"{name}({new_args})"

                # Use a lookahead to avoid matching definition (ends with {)
                # This regex is simplified and might match some false positives if method name is common
                content = re.sub(rf'({method_name})\(([^)]*)\)(?!\s*\{{)', 
                                add_context_call, content)
                changed = True
        
        if changed:
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(content)

if __name__ == "__main__":
    fix_undefined_context('analysis_output_6.txt')
