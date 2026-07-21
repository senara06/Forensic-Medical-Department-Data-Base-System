import os
import re

template_dir = r"C:\Users\ASUS\.gemini\antigravity\scratch\forensic_db_system\app\templates"

# Regex to find inputs, selects, textareas that are missing the 'required' attribute, excluding certain types
tag_pattern = re.compile(r'<(input|select|textarea)([^>]+)>', re.IGNORECASE)

def add_required(match):
    tag = match.group(1)
    attrs = match.group(2)
    
    # Don't add required to hidden inputs, submit buttons, checkboxes, or if already required
    if 'required' in attrs.lower():
        return match.group(0)
    
    if tag.lower() == 'input':
        if re.search(r'type=[\'"]?(hidden|submit|button|checkbox|radio)[\'"]?', attrs, re.IGNORECASE):
            return match.group(0)
            
    # Add required attribute
    if attrs.endswith('/'):
        return f'<{tag}{attrs[:-1]} required/>'
    else:
        return f'<{tag}{attrs} required>'

for filename in os.listdir(template_dir):
    if filename.endswith(".html"):
        filepath = os.path.join(template_dir, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
            
        new_content = tag_pattern.sub(add_required, content)
        
        if content != new_content:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"Updated {filename}")
print("Done!")
