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

def generate_class_setup():
    setup_code = """func setup_class(team: int, class_enum: int) -> void:
\tif not loadout_manager:
\t\tawait ready
\t\t
\tloadout_manager.drop_all()
\t
\tif team == 0: # Roofers
\t\tif class_enum == TeamManager.RooferClass.NAILER:
\t\t\tvar pry_bar = load("res://scripts/weapons/melee/pry_bar.gd").new()
\t\t\tvar nailgun = load("res://scripts/weapons/ranged/nailgun.gd").new()
\t\t\tvar ladder = load("res://scripts/weapons/gadgets/extension_ladder_tool.gd").new()
\t\t\t
\t\t\tloadout_manager.set_tool(LoadoutManager.Slot.MELEE, pry_bar)
\t\t\tloadout_manager.set_tool(LoadoutManager.Slot.RANGED, nailgun)
\t\t\tloadout_manager.set_tool(LoadoutManager.Slot.GADGET, ladder)
"""
    for c in roofers:
        c_lower = c.lower()
        setup_code += f"""\t\telif class_enum == TeamManager.RooferClass.{c}:
\t\t\tvar m = load("res://scripts/weapons/melee/{c_lower}_melee.gd").new()
\t\t\tvar r = load("res://scripts/weapons/ranged/{c_lower}_ranged.gd").new()
\t\t\tvar g = load("res://scripts/weapons/gadgets/{c_lower}_gadget.gd").new()
\t\t\tloadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
\t\t\tloadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
\t\t\tloadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
"""

    setup_code += """\t
\telif team == 1: # Landscapers
\t\tif class_enum == TeamManager.LandscaperClass.GARDENER:
\t\t\tvar knife = load("res://scripts/weapons/melee/pocket_knife.gd").new()
\t\t\tvar slingshot = load("res://scripts/weapons/ranged/slingshot.gd").new()
\t\t\tvar ladder = load("res://scripts/weapons/gadgets/extension_ladder_tool.gd").new()
\t\t\t
\t\t\tloadout_manager.set_tool(LoadoutManager.Slot.MELEE, knife)
\t\t\tloadout_manager.set_tool(LoadoutManager.Slot.RANGED, slingshot)
\t\t\tloadout_manager.set_tool(LoadoutManager.Slot.GADGET, ladder)
"""
    for c in landscapers:
        c_lower = c.lower()
        setup_code += f"""\t\telif class_enum == TeamManager.LandscaperClass.{c}:
\t\t\tvar m = load("res://scripts/weapons/melee/{c_lower}_melee.gd").new()
\t\t\tvar r = load("res://scripts/weapons/ranged/{c_lower}_ranged.gd").new()
\t\t\tvar g = load("res://scripts/weapons/gadgets/{c_lower}_gadget.gd").new()
\t\t\tloadout_manager.set_tool(LoadoutManager.Slot.MELEE, m)
\t\t\tloadout_manager.set_tool(LoadoutManager.Slot.RANGED, r)
\t\t\tloadout_manager.set_tool(LoadoutManager.Slot.GADGET, g)
"""
    return setup_code

pc_path = "scripts/characters/player_character.gd"
with open(pc_path, "r") as f:
    content = f.read()

# Replace setup_class
new_setup = generate_class_setup()

# Find the start of setup_class and replace until the next func or end of file
start_idx = content.find("func setup_class(team: int, class_enum: int) -> void:")
if start_idx != -1:
    end_idx = content.find("func ", start_idx + 10)
    if end_idx == -1:
        end_idx = len(content)
    
    new_content = content[:start_idx] + new_setup + "\n" + content[end_idx:]
    with open(pc_path, "w") as f:
        f.write(new_content)
    print("Updated player_character.gd!")
else:
    print("Error: Could not find setup_class in player_character.gd")

