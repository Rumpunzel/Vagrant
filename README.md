# Vagrant

*Vagrant* (working title) is a pen & paper RPG. Its rules live in `obsidian_vault/Vagrant/WIP 5/`; `Rules Reference.md` there sums them up.

This repository is also a personal playground: a digital prototype in Godot to try out the rules and some game architecture. Many of its assets are placeholders for personal use and belong to their respective owners (icons from [game-icons.net](https://game-icons.net), CC BY 3.0; font Grenze Gotisch, SIL OFL).

## Attributes

A character has three attributes, **Guts**, **Blood** and **Nerves**, each a simple **[2d6]** roll.

![attribute_rolling](https://github.com/Rumpunzel/Vagrant/blob/main/screenshots/attribute_rolling.PNG?raw=true)

## Character Creation

Each character chooses **2** origins from a list of origins with abilities and starting gear, one representing the world into which they were born, one representing the world or role they chose or were resigned to in their adult life.

For each **double** rolled for attributes, choose a rare origin.

![character_creation](https://github.com/Rumpunzel/Vagrant/blob/main/screenshots/character_creation.PNG?raw=true)

## Adventuring

The digital version plays as a choose-your-own-adventure with dice checks and fights. Locations, the events that can happen there and the people and creatures met on the way make up an adventure; what the player did changes what comes next.

![adventure](https://github.com/Rumpunzel/Vagrant/blob/main/screenshots/adventure.PNG?raw=true)

## Breath Dice and Resting

**Breath dice** (d4 to d12) are a character's effort and exhaustion. They are rolled for saves and fights; a die that comes up above the attribute it was rolled with is lost. Catching one's breath exhausts one die type to recover all the others.

![resting](https://github.com/Rumpunzel/Vagrant/blob/main/screenshots/resting.PNG?raw=true)

## Fights

A fight is a series of exchanges: both sides roll their breath dice, weapons and shields at once, and the higher threat gains the vantage, which their stance turns into more damage dealt (Guts), less damage taken (Blood) or an unnerved foe (Nerves). Forcing a weapon or shield beyond one's strength costs threat and wears the gear down; armour blocks certain results. What gets through becomes an injury, which lowers all attributes until a character can no longer resist.

## The Prototype

Made with Godot 4.6 (GDScript): open the project in the editor, or run it with `godot --path .`. `CLAUDE.md` describes the code's layout and conventions.
