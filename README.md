# Perk Descriptions

A Project Zomboid (Build 42) mod that fixes the skill tooltip in the character
info menu.

The engine builds the description key from the *translated* skill name
(`IGUI_perks_Carpinteria_Description`), but the game only ships the
descriptions under the English name (`IGUI_perks_Carpentry_Description`). In
every language but English the key does not exist, so the tooltip shows the
raw key instead of the description.

This mod looks the key up at runtime, so the description the game already
ships translated is used — in all 28 languages, with a single file.

- Workshop: <https://steamcommunity.com/sharedfiles/filedetails/?id=3819208492>
- Mod id: `PZPerkDescriptions` (the value that goes in a server `Mods=` list)
- Requires Build 42 or newer. No other mods needed.

## Layout

```
mods/PZPerkDescriptions/    the mod published to the Workshop
generar.py                 regenerates the tooltip patch from the game files
workshop/ficha.json        listing data: title, descriptions per language
workshop/preview.png       cover image, 256x256
workshop/gallery/          carousel images, 1280x720
```

The listing images and the upload itself are handled by
[pz-mod-toolbox](https://github.com/facundoramos-dev/pz-mod-toolbox).

## License

GPL-3.0, see [`LICENSE`](LICENSE).
