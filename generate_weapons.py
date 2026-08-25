import os

def create_weapon_script(path, class_name, tool_name, slot_type_int, is_melee=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    
    extends_class = "BaseMelee" if is_melee else "BaseTool"
    
    # Calculate scale/rotation/type specific defaults based on what it is
    scale = "(1.5, 1.5, 1.5)" if is_melee else "(0.8, 0.8, 0.8)"
    rot_x = "-60" if is_melee else "0"
    
    content = f"""class_name {class_name}
extends {extends_class}

func _ready() -> void:
\ttool_name = "{tool_name}"
\tdamage = 15.0
\tcooldown = 0.5
\tslot_type = {slot_type_int} # 0:Melee, 1:Ranged, 2:Gadget
\t
"""
    if is_melee:
        content += "\tswing_duration = 0.2\n"
        content += "\tis_thrust = false\n"
        
    content += "\tsuper._ready()\n\n"
    
    if is_melee:
        content += "\tfor child in get_children():\n"
        content += "\t\tif child is MeshInstance3D:\n"
        content += "\t\t\tchild.queue_free()\n\n"
    
    content += f"""\tvar visual_root = Node3D.new()
\tvisual_root.rotation_degrees.x = {rot_x}
\tadd_child(visual_root)
\t
\tvar placeholder = MeshInstance3D.new()
\tvar mesh = BoxMesh.new()
\tmesh.size = Vector3{scale}
\tvar mat = StandardMaterial3D.new()
\tmat.albedo_color = Color(randf(), randf(), randf())
\tmesh.material = mat
\tplaceholder.mesh = mesh
\tvisual_root.add_child(placeholder)
"""

    with open(path, "w") as f:
        f.write(content)

roofers = [
    "FOREMAN", "TAR_KING", "SHINGLE_SLINGER", "GUTTER_SNIPER",
    "CLEANUP_GUY", "APPRENTICE", "MAG_SWEEP", "ELECTRICIAN", "HVAC_TECH"
] # NAILER is already done

landscapers = [
    "LUMBERJACK", "BOTANIST", "MOWER", "TRIMMER",
    "BLOWER", "RAKER", "SPRINKLER", "CLIMBER", "HOBBYIST"
] # GARDENER is already done

base_path = "scripts/weapons"

def process_roster(roster, prefix):
    for c in roster:
        c_lower = c.lower()
        
        # Melee
        create_weapon_script(
            f"{base_path}/melee/{c_lower}_melee.gd",
            f"{prefix}{c.title().replace('_', '')}Melee",
            f"{c.replace('_', ' ').title()} Melee",
            0, True
        )
        # Ranged
        create_weapon_script(
            f"{base_path}/ranged/{c_lower}_ranged.gd",
            f"{prefix}{c.title().replace('_', '')}Ranged",
            f"{c.replace('_', ' ').title()} Ranged",
            1, False
        )
        # Gadget
        create_weapon_script(
            f"{base_path}/gadgets/{c_lower}_gadget.gd",
            f"{prefix}{c.title().replace('_', '')}Gadget",
            f"{c.replace('_', ' ').title()} Gadget",
            2, False
        )

process_roster(roofers, "Roofer")
process_roster(landscapers, "Landscaper")

print("Generated all remaining 54 placeholder weapon scripts!")
