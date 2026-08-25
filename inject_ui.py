import os
import re

roofers = [
    "FOREMAN", "TAR_KING", "SHINGLE_SLINGER", "GUTTER_SNIPER",
    "CLEANUP_GUY", "APPRENTICE", "MAG_SWEEP", "ELECTRICIAN", "HVAC_TECH"
]
landscapers = [
    "LUMBERJACK", "BOTANIST", "MOWER", "TRIMMER",
    "BLOWER", "RAKER", "SPRINKLER", "CLIMBER", "HOBBYIST"
]

def generate_item_options():
    items = [
        '\t{"name": "Pry Bar (Melee)", "path": "res://scripts/weapons/melee/pry_bar.gd"}',
        '\t{"name": "Pocket Knife (Melee)", "path": "res://scripts/weapons/melee/pocket_knife.gd"}',
        '\t{"name": "Nailgun (Ranged)", "path": "res://scripts/weapons/ranged/nailgun.gd"}',
        '\t{"name": "Slingshot (Ranged)", "path": "res://scripts/weapons/ranged/slingshot.gd"}',
        '\t{"name": "Extension Ladder (Gadget)", "path": "res://scripts/weapons/gadgets/extension_ladder_tool.gd"}'
    ]
    
    for c in roofers:
        c_lower = c.lower()
        c_title = c.replace('_', ' ').title()
        items.append(f'\t{{"name": "[R] {c_title} Melee", "path": "res://scripts/weapons/melee/{c_lower}_melee.gd"}}')
        items.append(f'\t{{"name": "[R] {c_title} Ranged", "path": "res://scripts/weapons/ranged/{c_lower}_ranged.gd"}}')
        items.append(f'\t{{"name": "[R] {c_title} Gadget", "path": "res://scripts/weapons/gadgets/{c_lower}_gadget.gd"}}')
        
    for c in landscapers:
        c_lower = c.lower()
        c_title = c.replace('_', ' ').title()
        items.append(f'\t{{"name": "[L] {c_title} Melee", "path": "res://scripts/weapons/melee/{c_lower}_melee.gd"}}')
        items.append(f'\t{{"name": "[L] {c_title} Ranged", "path": "res://scripts/weapons/ranged/{c_lower}_ranged.gd"}}')
        items.append(f'\t{{"name": "[L] {c_title} Gadget", "path": "res://scripts/weapons/gadgets/{c_lower}_gadget.gd"}}')
        
    return "var item_options = [\n" + ",\n".join(items) + "\n]\n"

tl_path = "scripts/levels/test_level.gd"
with open(tl_path, "r") as f:
    content = f.read()

# Replace item_options array
start_idx = content.find("var item_options = [")
if start_idx != -1:
    end_idx = content.find("]", start_idx)
    end_idx = content.find("\n", end_idx) + 1
    
    new_content = content[:start_idx] + generate_item_options() + content[end_idx:]
    with open(tl_path, "w") as f:
        f.write(new_content)
    print("Updated test_level.gd!")
else:
    print("Error: Could not find item_options in test_level.gd")
