# Gun Game v1.0 - Unreal Tournament 99 Game Mode
## Description
A UT99 mod that adds a custom game mode based on other game's implementation of the mode.  
It is written in UnrealScript (.uc). It is completely playable, but still requires polishing the code.

## Installation
To install the mod make sure to save the files located in the `System` folder in the folder of the same name in your installation of Unreal Tournament.

The source code of the mod is available for further modification in the `GunGame/Classes` folder.  
After any modifications make sure to recompile the code.

## Rules
* The mode supports `DM-` maps.
* Every player starts with the Enforcer.
* Every point a player gets changes their weapon in the next order:
  * Enforcer
  * Bio Rifle
  * Shock Rifle
  * Pulse Gun
  * Ripper
  * Minigun
  * Flak Cannon
  * Rocket Launcher
  * Sniper Rifle
  * Translocator
* In case the point goal is set above 10, the weapon cycle repeats after a player reaches 10 points.
* There are no ammo packs nor weapons in the map.
* If a player or bot runs out of ammo they are given the choice to restart.
* **First player to reach the score goal wins.**
