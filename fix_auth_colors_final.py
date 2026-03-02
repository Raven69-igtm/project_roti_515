import os
import re

# Extended color map for Auth features
color_map = {
    r"Color\(0xFFF8F7F6\)": "context.colors.bgColor",
    r"Color\(0xFF111827\)": "context.colors.textDark",
    r"Color\(0xFF6B7280\)": "context.colors.textGrey",
    r"Color\(0xFF9CA3AF\)": "context.colors.textHint",
    r"Color\(0xFFE5E7EB\)": "context.colors.divider",
    r"Color\(0xFFF3F4F6\)": "context.colors.surface",
    r"Color\(0xFF1B140D\)": "context.colors.textDark",
    r"Color\(0xFFE7DBCF\)": "context.colors.divider",
    r"Color\(0xFF9A734C\)": "context.colors.textHint",
    r"Color\(0xFFD47311\)": "context.colors.primaryOrange",
    r"Color\(0xFF4B5563\)": "context.colors.textGrey",
    r"Color\(0xFF1F2937\)": "context.colors.textDark",
    r"Color\(0xFF22C55E\)": "context.colors.success",
    r"Color\(0xFF0F172A\)": "context.colors.textDark",
    r"Color\(0xFF64748B\)": "context.colors.textGrey",
    r"Color\(0xFF94A3B8\)": "context.colors.textHint",
    r"Color\(0xFF1A1A1A\)": "context.colors.textDark",
    r"Color\(0xFF757575\)": "context.colors.textGrey",
    r"Color\(0xFFFF6B00\)": "context.colors.primaryOrange",
    r"Colors\.black87": "context.colors.textDark",
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    needs_theme = False
    original = content
    
    for pattern, replacement in color_map.items():
        if re.search(pattern, content):
            needs_theme = True
            content = re.sub(pattern, replacement, content)
        
    # Replace Colors.white depending on context
    if "LoginGoogleButton" in content or "login_google_button.dart" in filepath:
         if re.search(r'color:\s*Colors\.white,', content):
             content = re.sub(r'color:\s*Colors\.white,', r'color: context.colors.surface,', content)
             needs_theme = True

    if re.search(r'color:\s*Colors\.white,\s*(?=borderRadius:)', content):
        content = re.sub(r'color:\s*Colors\.white,\s*(?=borderRadius:)', r'color: context.colors.surface, ', content)
        needs_theme = True
        
    if re.search(r'color:\s*Colors\.white,\s*(?=border:)', content):
        content = re.sub(r'color:\s*Colors\.white,\s*(?=border:)', r'color: context.colors.surface, ', content)
        needs_theme = True
        
    if re.search(r'color:\s*Colors\.white,\s*(?=boxShadow:)', content):
        content = re.sub(r'color:\s*Colors\.white,\s*(?=boxShadow:)', r'color: context.colors.surface, ', content)
        needs_theme = True
        
    if re.search(r'color:\s*Colors\.white,\s*(?=shape:)', content):
        content = re.sub(r'color:\s*Colors\.white,\s*(?=shape:)', r'color: context.colors.surface, ', content)
        needs_theme = True

    if content != original:
        if needs_theme and "import 'package:roti_515/core/theme/app_theme.dart';" not in content:
            lines = content.split('\n')
            inserted = False
            for i, line in enumerate(lines):
                if line.startswith('import'):
                    lines.insert(i, "import 'package:roti_515/core/theme/app_theme.dart';")
                    inserted = True
                    break
            if not inserted:
                lines.insert(0, "import 'package:roti_515/core/theme/app_theme.dart';")
            content = '\n'.join(lines)
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(r"c:\project_roti_515\lib\features\auth"):
    for file in files:
        if file.endswith(".dart"):
            process_file(os.path.join(root, file))
