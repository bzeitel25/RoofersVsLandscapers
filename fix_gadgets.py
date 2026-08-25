import os
import glob

gadgets_path = r"c:\Users\bzeit\OneDrive\Documents\Books\Universe\Roofers vs Landscapers\scripts\weapons\gadgets\*.gd"

for file_path in glob.glob(gadgets_path):
    with open(file_path, "r") as f:
        content = f.read()
    
    modified = False
    
    if "can_attack()" in content:
        content = content.replace("if not can_attack(): return", "if not can_use(): return")
        modified = True
        
    if "last_attack_time = Time.get_ticks_msec() / 1000.0" in content:
        content = content.replace("last_attack_time = Time.get_ticks_msec() / 1000.0", "_start_cooldown()")
        modified = True
        
    if "can_use()" not in content and "primary_action(" in content:
        # Add missing cooldown checks
        content = content.replace("func primary_action() -> void:\n\tif not wielder", "func primary_action() -> void:\n\tif not can_use(): return\n\t_start_cooldown()\n\tif not wielder")
        content = content.replace("func primary_action() -> void:\n\t_deploy", "func primary_action() -> void:\n\tif not can_use(): return\n\t_start_cooldown()\n\t_deploy")
        modified = True
        
    if modified:
        with open(file_path, "w") as f:
            f.write(content)
        print(f"Fixed {os.path.basename(file_path)}")

print("Done fixing gadgets.")
