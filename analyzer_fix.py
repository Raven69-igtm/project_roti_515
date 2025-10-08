import os
import re

def fix_from_analyzer(log_file):
    content = ""
    for enc in ['utf-16', 'utf-8', 'latin-1']:
        try:
            with open(log_file, 'r', encoding=enc) as f:
                content = f.read()
            if "error" in content:
                print(f"Read successful with {enc}")
                break
        except:
            continue
    
    if not content:
        print("Could not read log file.")
        return

    content = content.replace('\r\n', '\n')
    
    # Match various constant-related errors
    error_types = [
        "Invalid constant value",
        "The constructor being called isn't a const constructor",
        "Arguments of a constant creation must be constant expressions",
        "Constant values from a context extension cannot be used in a constant context", # Just in case
        "The name 'context' is already defined", # Cleanup for my previous bad fix
    ]
    
    pattern = r'error - (' + '|'.join(error_types) + r') - (.*?):(\d+):(\d+)'
    matches = re.findall(pattern, content)
    print(f"Found {len(matches)} potential error matches")
    
    # match is (error_type, filepath, line, col)
    # Deduplicate and sort
    matches = sorted(list(set(matches)), key=lambda x: (x[1], -int(x[2])))
    
    current_file = None
    lines = []
    
    for err_type, filepath, line_str, col_str in matches:
        line_num = int(line_str) - 1
        full_path = os.path.join(r'c:\project_roti_515', filepath)
        
        if full_path != current_file:
            if current_file and lines:
                with open(current_file, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
            
            current_file = full_path
            if not os.path.exists(current_file):
                print(f"File not found: {current_file}")
                lines = []
                continue
            with open(current_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
        
        if line_num < len(lines):
            if "The name 'context' is already defined" in err_type:
                # Remove 'BuildContext context,' or 'context,' from parameters if it's a duplicate
                lines[line_num] = lines[line_num].replace('BuildContext context,', '').replace('context,', '')
                print(f"Cleaned up duplicate context in {filepath}:{line_num+1}")
            else:
                found_const = False
                # Look backwards for 'const'
                for i in range(line_num, max(-1, line_num - 20), -1):
                    if 'const ' in lines[i]:
                        lines[i] = lines[i].replace('const ', '', 1)
                        found_const = True
                        print(f"Fixed const in {filepath} at line {i+1}")
                        break
                if not found_const:
                    print(f"Could not find const for error at {filepath}:{line_num+1} ({err_type})")

    if current_file and lines:
        with open(current_file, 'w', encoding='utf-8') as f:
            f.writelines(lines)

if __name__ == "__main__":
    fix_from_analyzer('analysis_output_6.txt')
