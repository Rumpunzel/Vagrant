# Items — Plan

## Decisions (2026-11-05, user)
- Gear is an item: `WeaponProfile`, `ArmorProfile`, `ShieldProfile` extend `ItemProfile` (name, icon, description shared). One inventory, one gain / lose effect, one loot list for both.
- No carrying limit for now.
- Items have no rules of their own yet (story items: keys, gifts, trades); camp rations, repairs etc. later.
- Loot: a monster's own gear (with its marks) plus a loot list on the encounter (`AdventureEncounter.loot`), picked per item.
- Gaining and losing is told on the next page ("You gain the Sword and 2 Rations.").
- Armour stacks: every carried piece protects (pieces of one kind too), for now.
- A search with nothing left isn't offered at all (not greyed out).

## Built
- **Carrying** (`Actor`): plain items in a number (`items`), gear as pieces with their own marks (`weapons`, `armor`, `shields`). `gain(item, count)` (gear: fresh pieces), `lose(item, count)` (gear: the most worn usable pieces first; returns how many), `count_of(item)` (gear: pieces not ruined), `hand_over(piece, to)` (marks and all), `get_gear()`, signal `carried_changed`. `ItemProfile.is_gear()`. Gear among a profile's `items` is carried as pieces.
- **Saving:** gear by its profile (`ResourceId`) plus marks and ruined; a piece whose profile has no ID, or a save from before (no profiles), takes the piece at its place among those handed out. Loot left per encounter in `StoryWorld` (`loot_left`; older saves: none).
- **Story:** `AdventureGainConsequence` / `AdventureLoseConsequence` (item, count) through `Story.give` / `Story.take`; `AdventureCarriesCondition` (item, at least n; `negated`: "Doesn't carry", fewer than n). What was gained and lost since the last page is told as a paragraph in italics before the next page's text. Journal: `gained` / `lost` (actor, item, count); the debug panel shows them.
- **Loot:** `AdventureLootDecision` (encounter: named, else its event's own) opens a page the story makes (`StoryPage.in_between`, like a fight's exchanges: not in the page stack, not counted, not saved on): "Take the Knife (marked 3).", "Take 2 Rations.", "Take everything.", "Leave the rest.". The page re-lists after each take; taking the last of it, or leaving, follows the decision's transition (none: back). Gear comes off the monster (`hand_over`), the rest out of `StoryWorld.get_loot_left` / `take_loot`. Not offered once nothing is left.
- **Adventure editor:** "+ Loot event" on monster encounters: a template option "Searching the X" (when it is dead; "Search the X." → ↺ Host), editable like any other (e.g. "is beaten" for a sleeping monster); "loot" in the add menu ("Search it."), loot cards ("Loot: Bandit", search icon), tooltip "Finds on Bandit: Knife, 2 Rations"; Gain / Lose effects and Carries condition in the tag menus (item set in the Inspector); problem: a search that finds nothing.
- **Inventory panel** (`Inventory`, character creation and the character sheet): grouped Weapons, Shields, Armour, Items in columns side by side (wrapping where narrow; at least a row high, up to its columns' height, scrolling in less, so it never pushes character creation's Continue off a small screen); each piece with its icon (else its group's), its die with the die's icon (or what it blocks), the attribute it is wielded with (icon, its colour), and its faces with the marked ones struck out in red; ruined pieces faded; items with their count; each row's tooltip: the description and what it does in a fight. Gear and items have icons from `assets/game_icons` (Knife, Club, Sword, the shields, the armour, Rations, Waterskin). The weapon choice shows faces the same way (`Inventory.describe_faces`). The hidden load sketch (belt, pouch, satchel, load levels) is kept as it was.
- **Editor item picks:** the tag menus offer "Gain › Sword", "Lose › …", "Carries › …", "Doesn't carry › …" for every item in the project (`AdventureMakers.find_items`: `.tres` files whose header names an item class, outside `addons`; weapons, shields, armour, items, then by name), with the items' icons in the menus and on the tags; the count is set in the Inspector.
- Tests: carrying (6), saving gear and loot left (2), effects and conditions (5), told on the next page (1), looting in the story (2), editor (3).

## Open
- [ ] Choosing which piece to hand over when losing gear (now: the most worn)
- [ ] Inventory actions (use, drop) once items do something; rations at camp, repairs while resting (rules)
- [ ] Loot of one-off fights' `enemies` (only encounters have loot now)
- [ ] Carrying limits, armour slots (later, with the rules)
- [ ] Inventory panel overhaul (user, later); the current columns + scroll are a stopgap so character creation fits at 1568×884

## Log
- 2026-11-05: plan agreed and slice built (see Built).
- 2026-11-06: loot template (user: looting dead things will happen often): "+ Loot event" on monster encounters.
- 2026-11-06: inventory panel readable at a glance (see Built), icons for the gear and items.
- 2026-11-06: inventory in columns and scrolling: listed one under another it pushed character creation's Continue off a 1568×884 window (the UI is laid out at the window's size, 1920×1080 by design).
- 2026-11-06: editor item picks in submenus (`AdventureActionMenu`: "Group › item" keys) and "Doesn't carry" (negated Carries).
