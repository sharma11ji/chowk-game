# CHOWK - Apna Mohalla (v2 / 0.2.0)

A small top-down Indian town exploration game for a portrait phone screen.

## Open and play
Open project.godot in Godot 4.7.2 stable and run the project.

- Tap or click an open part of the town to walk there. The route goes around buildings.
- Hold or drag the bottom-left directional pad to move manually.
- Desktop testing also supports WASD and arrow keys.
- The blue-shirt character with the pale yellow ring is the player.

## In this version
- Main road and a small crossing, chai tapri, kirana store, four houses.
- Original primitive art: striped shop awnings, chai tables and cups, sabzi cart,
  trees, parked scooters, water pump and utility poles.
- Two stationary NPCs: Raju and Gupta ji, with dialogue and the Raju ki Chai mission. No interiors.
- CharacterBody2D player, solid building/tree/cart/map-boundary collision.
- AStarGrid2D tap navigation. Touch controls and fixed 720 x 1280 composition.

## Test
    godot --headless --path . --script res://smoke.gd

The smoke test verifies tap routes to both shops, routes around obstructions,
rejected roof/HUD targets, house-wall collision, touch-pad movement/release,
and world-boundary collision.

Real game frames can be saved without an editor:
    godot --path . --resolution 720x1280 -- --capture=/absolute/path/town.png
    godot --path . --resolution 720x1280 -- --pose=chai --capture=/absolute/path/chai.png

## Status and limits
Built and rendered using Godot 4.7.2 stable on Linux. The supplied PNG previews
are real game frames, not mockups. Desktop render and automated gameplay tests
passed. A debug-signed Android APK is provided as a release asset. No web export or APK-store release is provided.
Physical Android/Chrome performance and device touch behaviour are not yet
verified. Physical-phone checks are the next step; the debug APK is a prototype, not a store-ready build.

## Project layout
project.godot: configuration
town.tscn: entry scene
town.gd: illustration, world setup, controls, collision and navigation
smoke.gd: automated gameplay smoke test

All town illustrations were drawn for this project using Godot primitives.
No downloaded art, paid assets or external art dependencies are included.

## Android build
Portrait APK: package com.sharma11ji.chowk, version 0.1.0.
Includes ARM64 and ARMv7, requires Android 7.0 or newer.
No Android permissions requested. Offline exploration; no accounts or ads.
Use the Android export preset with Godot 4.7.2 export templates and your local
Android SDK configured in Godot editor settings. Debug signing is local only.


## Raju ki Chai mission
Raju ki Chai is implemented. Approach either NPC to show Baat karo.
Talk to Raju, collect milk from Gupta ji, and return to Raju to receive chai.
Dialogue changes before the mission, while fetching or carrying milk, and after
completion. Real Area2D circles detect the player. The dialogue pauses movement
and the bottom panel has a large close button. Progress lasts for the current
session only; restarting the game resets the mission. There is no save system.
Run mission_smoke.gd for mission tests, in addition to smoke.gd for v1 regression.

## v2 installation
Download CHOWK-v2-debug.apk from the v0.2.0 release. Uninstall v1 first.
The v1 build used a temporary CI signing key which was not preserved; v2 cannot
update that installation in place. No v1 saves exist. v2 is session-only too.
Debug-signed test build, not a Play Store release. If a security scan warns, stop
and share a screenshot rather than disabling protections.
