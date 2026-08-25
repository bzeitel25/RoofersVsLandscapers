import os
import re

weapon_stats = {
    # Roofers
    "pry_bar.gd": "knockback_multiplier = 2.5\n\tstun_chance = 0.1",
    "tar_king_melee.gd": "slow_chance = 0.3",
    "shingle_slinger_melee.gd": "bleed_chance = 0.2",
    "gutter_sniper_melee.gd": "crit_chance = 0.35\n\tcrit_multiplier = 2.5",
    "cleanup_guy_melee.gd": "slow_chance = 0.25",
    "apprentice_melee.gd": "bleed_chance = 0.1\n\tlifesteal_percent = 0.1", # Tape measure whip
    "mag_sweep_melee.gd": "knockback_multiplier = 3.0\n\tstun_chance = 0.15",
    "electrician_melee.gd": "stun_chance = 0.25",
    "hvac_tech_melee.gd": "stun_chance = 0.2",
    
    # Landscapers
    "pocket_knife.gd": "crit_chance = 0.15",
    "mower_melee.gd": "bleed_chance = 0.4",
    "trimmer_melee.gd": "bleed_chance = 0.15",
    "blower_melee.gd": "knockback_multiplier = -1.5", # Rake pulls enemies in!
    "raker_melee.gd": "knockback_multiplier = 1.5\n\tslow_chance = 0.15",
    "sprinkler_melee.gd": "crit_chance = 0.15",
    "climber_melee.gd": "bleed_chance = 0.2\n\tstun_chance = 0.1",
    "hobbyist_melee.gd": "crit_chance = 0.3\n\tknockback_multiplier = 0.5" # Puncture, less knockback
}

directory = "scripts/weapons/melee"

for filename, stats in weapon_stats.items():
    filepath = os.path.join(directory, filename)
    if os.path.exists(filepath):
        with open(filepath, "r") as f:
            content = f.read()
        
        # We look for the end of the _init function to inject our lines
        # In most scripts, we can just insert before the final line of _init, or right after swing_duration
        
        if "extends" in content:
            # simple regex to insert at the end of _init()
            # usually _init has a few lines like swing_duration = X
            # Let's just insert after 'cooldown = ' or 'swing_duration = '
            
            # Find a good anchor
            if "swing_duration =" in content:
                # Insert right after swing_duration
                pattern = r"(swing_duration\s*=\s*[\d\.]+)"
                replacement = r"\1\n\t" + stats
                new_content = re.sub(pattern, replacement, content, count=1)
                
                if new_content != content:
                    with open(filepath, "w") as f:
                        f.write(new_content)
                    print(f"Updated {filename}")
                else:
                    print(f"Regex failed for {filename}")
            else:
                print(f"Could not find anchor in {filename}")
    else:
        print(f"File not found: {filename}")
