#!/usr/bin/env python3
"""Generates the Lua patch that fixes the skill descriptions.

The engine builds the description key by concatenating the TRANSLATED skill
name:

    ISSkillProgressBar.lua:78 -> getText("IGUI_perks_"..perk:getName().."_Description")

that is, "IGUI_perks_Carpinteria_Description". But the game only ships the
descriptions under the ENGLISH name, "IGUI_perks_Carpentry_Description", and
those keys ARE translated into every language. In any other language the key
the engine looks for does not exist and the tooltip shows the raw text.

The first version of this mod wrote 28 translation files that duplicated text
the game already ships. This one overrides
media/lua/client/XpSystem/ISUI/ISSkillProgressBar.lua and looks up the right
key: a single file covers every language, because at runtime the translated
name is inverted with the game translator.

Usage:
    python3 generate.py [path/to/server-files/media/lua/shared/Translate] [path/to/mod]
"""
import json
import os
import sys

# Internal ids of PerkFactory (zombie.characters.skills.PerkFactory.init) for
# the child skills: the ones that show a tooltip in the character info menu.
# The parent categories (CombatMelee, Survivalist, Crafting, ...) have no
# description and the interface does not draw a tooltip for them.
CHILD_SKILL_IDS = [
    "Axe", "Blunt", "SmallBlunt", "LongBlade", "SmallBlade", "Spear", "Maintenance",
    "Aiming", "Reloading", "Carpentry", "Carving", "Cooking", "Electricity", "Doctor",
    "Glassmaking", "FlintKnapping", "Masonry", "Blacksmith", "Mechanics", "Pottery",
    "Tailoring", "MetalWelding", "Fishing", "Foraging", "Tracking", "Trapping", "Fitness",
    "Strength", "Lightfooted", "Nimble", "Sprinting", "Sneaking", "Husbandry", "Butchering",
    "Farming",
]

MOD_ROOT = "mods/PZPerkDescriptions/common"
OUTPUT_PATH = "media/lua/client/XpSystem/ISUI/ISSkillProgressBar.lua"
VANILLA_PATH = "server-files/media/lua/client/XpSystem/ISUI/ISSkillProgressBar.lua"

# Block inserted before updateTooltip: the two tables plus the helper.
HELPER = '''-- ---------------------------------------------------------------------------
-- Perk descriptions (PZPerkDescriptions)
--
-- The engine builds the description key by concatenating the TRANSLATED skill
-- name, "IGUI_perks_Carpinteria_Description", but the game only ships the
-- descriptions under the ENGLISH name,
-- "IGUI_perks_Carpentry_Description". In any language the key the engine looks
-- for does not exist, so the tooltip ends up showing the raw text.
--
-- This patch inverts the name: it translates every skill id with the game
-- translator and compares it with the name the tooltip shows, to find the
-- right key. A single file covers every language, and the descriptions shown
-- are the game's own, not a copy.
-- ---------------------------------------------------------------------------

-- internal id -> english name (the one used by the description key)
local ENGLISH_NAMES = {
@@NOMBRES@@
}

-- internal id -> english text. Fallback for the languages The Indie Stone has
-- not translated yet (today only Ukrainian, with 6 of the 35).
local ENGLISH_TEXTS = {
@@TEXTOS@@
}

local indexCache = nil

local function descriptionIndex()
	if indexCache ~= nil then
		return indexCache
	end
	local index = {}
	for id, _ in pairs(ENGLISH_NAMES) do
		local name = getTextOrNull("IGUI_perks_" .. id)
		if name ~= nil and name ~= "" then
			index[name] = id
		end
	end
	indexCache = index
	return index
end

-- Returns (description in the player language, base key), or (nil, nil) for the
-- skills that are not in the table, like the ones added by other mods.
local function perkDescription(perk)
	local id = descriptionIndex()[perk:getName()]
	if id == nil then
		return nil, nil
	end
	local key = "IGUI_perks_" .. ENGLISH_NAMES[id] .. "_Description"
	local text = getTextOrNull(key)
	if text == nil or text == "" then
		text = ENGLISH_TEXTS[id]
	end
	return text, key
end

'''

# The two lines to replace inside updateTooltip.
OLD = '''	self.message = self.message .. " <LINE><LINE> " .. getText("IGUI_perks_"..self.perk:getName().."_Description")
	local levelText = getTextOrNull("IGUI_perks_"..self.perk:getName().."_Description"..lvlSelected+1)
	if levelText ~= nil and levelText ~= "" then
		self.message = self.message .. " <LINE><LINE> " .. levelText
	end'''

NEW = '''	local description, descriptionKey = perkDescription(self.perk)
	if description ~= nil then
		self.message = self.message .. " <LINE><LINE> " .. description
	else
		-- skills outside the table (the ones from other mods): original behaviour
		self.message = self.message .. " <LINE><LINE> " .. getText("IGUI_perks_"..self.perk:getName().."_Description")
	end
	if descriptionKey ~= nil then
		local levelText = getTextOrNull(descriptionKey..lvlSelected+1)
		if levelText ~= nil and levelText ~= "" then
			self.message = self.message .. " <LINE><LINE> " .. levelText
		end
	end'''

MARKER = "function ISSkillProgressBar:updateTooltip(lvlSelected)"


def lua_string(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def main():
    source = sys.argv[1] if len(sys.argv) > 1 else \
        "server-files/media/lua/shared/Translate"
    mod_root = sys.argv[2] if len(sys.argv) > 2 else MOD_ROOT
    destination = os.path.join(mod_root, OUTPUT_PATH)

    en = load(os.path.join(source, "EN", "IG_UI.json"))

    rows = []
    for skill_id in CHILD_SKILL_IDS:
        english_name = en.get("IGUI_perks_" + skill_id)
        if english_name is None:
            print("  !! no english name, skipping:", skill_id)
            continue
        description_key = "IGUI_perks_" + english_name + "_Description"
        rows.append((skill_id, english_name, en.get(description_key)))
    missing = [i for i, _, d in rows if d is None]
    if missing:
        print("  !! the game ships no description for:", ", ".join(missing))

    names = "\n".join("\t%s = %s," % (i, lua_string(n)) for i, n, _ in rows)
    texts = "\n".join("\t%s = %s," % (i, lua_string(d or n)) for i, n, d in rows)

    # The patch is applied on top of a copy of the vanilla file: the override
    # only changes what it has to change, and it is easy to resync when The
    # Indie Stone updates the file.
    with open(VANILLA_PATH, encoding="utf-8") as f:
        vanilla = f.read()

    for piece, label in ((MARKER, "the updateTooltip marker"), (OLD, "lines 78-82")):
        if piece not in vanilla:
            raise SystemExit("the vanilla file changed: could not find " + label)

    patch = HELPER.replace("@@NOMBRES@@", names).replace("@@TEXTOS@@", texts)

    output = vanilla.replace(OLD, NEW, 1)
    output = output.replace(MARKER, patch + MARKER, 1)

    os.makedirs(os.path.dirname(destination), exist_ok=True)
    with open(destination, "w", encoding="utf-8", newline="\n") as f:
        f.write(output)

    different = [(i, n) for i, n, _ in rows if i != n]
    print(f"Done: {len(rows)} skills in {destination}")
    print("  id different from the english name (that was the bug):")
    for i, n in different:
        print("    %-12s -> %s" % (i, n))
    if not different:
        print("    (none, check it)")


if __name__ == "__main__":
    main()
