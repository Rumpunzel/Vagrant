# Logging and Saving — Plan

Status (2026-11-03): design chosen (option C); steps 1–3 (`ResourceId`, `GameRandom`, `GameLog`) built, on branch `feature/logging-and-saving`. "Decisions" holds what is settled, "Open" what isn't; the log at the end has the history.
Goal: (1) a log of what happens in a story, for debugging; (2) saving and loading a game in progress. Both need the same thing: a clear
list of the runtime state and a stable way to name content (pages, decisions, monsters) outside the running game.

## Decisions
- **Option C**: a story journal (debug log + visit counts) plus snapshots for saving.
- **No saving during fights** for now: no autosave while a fight is ongoing; loading puts one back at the last page before it.
- **A save slot per run, autosaved.** Starting a new run (new character / adventure) makes a new slot; each safe point overwrites it.
- **Refuse to load** if the adventure changed and a saved id no longer resolves (or the format version is unknown); say what is missing.
- **Log to disk only in debug builds** (`OS.is_debug_build()`); the journal itself is always kept (it goes into the save).
- **Seeded RNG now**: one RNG for dice and chance rolls, its seed and state in the save and the log. Cosmetic randomness (roll sounds) stays
  on the global one, so it doesn't shift game results.

## Where state lives now
| Owner | State | Notes |
|---|---|---|
| `Story` | `_adventure`, `_page_stack`, `_host`, `_location`, `_encounter`, `_entered_area` / `_first_time_in_area`, `_areas_been_in`, `_chance_rolls`, `_forced` / `_arrivals_while_forced` | Keys are `AdventurePage` objects |
| `Story` | `_page_log` (page → `StoryPage`s), `_decision_log` (decision → `StoryChoice`s) | Only their **counts** are read (`get_how_often_…`); the objects are history kept by accident |
| `Story` (mid-fight) | `_current_story_page.fight`, `_incapacitation_save`, `_after_incapacitation_save`, `_pending_choices`, `_summary_start`, the `EventQueue` | Callables and queued lambdas: can't be saved as is |
| `StoryWorld` | `_stages` (subject → track → stage), `_places` (encounter → locations) | `_encounter_of`, `_distances` are caches, rebuilt from the adventure |
| `Party` / `Character` | `character_profile` (may be made in character creation, not a file), `breath_dice`, `exhaustion`, `_injuries`, `weapons` / `armor` / `shields` (carried, droppable), `items`, `most_recently_chosen_attribute` | Nodes |
| `Monsters` / `Monster` | keyed by `[spawning page, host location]` + profile + index; `breath_dice`, `_injuries`, gear, `incapacitated`, `dead` | Encounter monsters live the whole story |
| `Fight` | `exchanges`, `incapacitated`, `outcome`, `_step_index`, `_paragraphs`, `armor_picks` | Already a record of each exchange |
| Randomness | `GameRandom` (dice, chances, marked faces) | Seeded per story start; the state goes into the save |
| Carried gear | `MarkRandomFacesModifier` marks random faces when a character carries its gear (on setting the profile) | Restoring a character re-carries: marked faces must be saved, not rolled again |
| Existing logs | `DiceLog` (UI, from `DiceRoller.die_rolled`), the fight summary paragraphs | Neither is written anywhere |

## Overlap
Both features need:
- **Names for content.** A save and a log line must say "page X", "decision Y" in a way that survives a restart. Files have UIDs; pages,
  events and decisions inside a file are sub-resources. `AdventurePlayFrom` already names those as `[file UID/path, resource_scene_unique_id]`
  — now one helper, `ResourceId`. Runtime-made decisions (turn back, failed save) need fixed names.
- **One list of what changes state.** Entering a page, choosing, a roll, a consequence, a stage change, a move, an injury, breath spent or
  caught, a fight exchange. The log writes these; a save must cover their effect.

## Options
**A. Snapshot only.** Each owner turns its state into a Dictionary and back (`to_save()` / `load_save()`); a `SaveGame` collects them.
Logging is a separate print-style logger.
+ Simple, robust against content edits that don't remove what the save names. − Log and save drift apart; two lists of state.

**B. Journal only (event sourcing).** Record every input (choices, dice results, chance rolls); load = start the adventure and replay.
The journal *is* the log.
+ One list; a bug report is a replayable run. − Replay must be exactly deterministic and run through `EventQueue` delays, typing and UI
(needs an instant mode); any content edit breaks old saves; slow for long runs.

**C. Hybrid (recommended).** A structured **story journal** of domain events (typed entries, content named by id) that both the debug log
and the visit counts read, plus **snapshots** of the state at safe points for saving. The journal goes into the save too.
+ `_page_log` / `_decision_log` become counts over the journal (one source); saves don't need replay; the journal still shows how one got
there. − Two mechanisms, but each simple.

## Design (option C)
- **`ResourceId`** (`custom_nodes/resource_id.gd`, static): resource ↔ string id: the file's UID (its path if it has none, e.g. `user://`),
  plus `::<resource_scene_unique_id>` for a resource stored inside a file, found again by walking what that file stores (Godot can't load
  a sub-resource by itself). Any resource, not only pages; runtime-made ones have no id (empty). `AdventurePlayFrom` uses it.
- **Journal** (`StoryJournal`, RefCounted, owned by `Story`): append-only `Array` of entries (`{t: "enter", page: id}`, `{t: "choose",
  decision: id}`, `{t: "roll", dice: …, margin: …}`, `{t: "stage", subject, track, stage}`, …). Signals for listeners. Replaces
  `_page_log` / `_decision_log` (counts per id).
- **Game log**: `GameLog.write(category, message)` (`custom_nodes/game_log.gd`, static, no dependencies) prints "HH:MM:SS category: …"
  in debug builds only. No own file: Godot's file logging (on by default) already writes stdout and the engine's errors to
  `user://logs/godot*.log`, the last few runs. No levels until something needs them. Later maybe an in-game debug panel
  (`OS.add_logger` could feed it). `Story.start_adventure` logs the adventure and seed; the journal will write each entry.
- **Snapshots**: each owner saves its own state (`Story`, `StoryWorld`, `Character`, `Monster` / `Monsters`) as plain Dictionaries of ids
  and numbers; `SaveGame` (RefCounted) collects them with a format version, the adventure id, the RNG state and the journal, and writes
  JSON to `user://saves/<run id>.json` (run id: start time).
  Character profiles made in character creation are saved by value (attributes, origins, name, portrait id).
- **Safe points / autosave**: when a page is shown with nothing queued and no fight ongoing. The snapshot holds the shown page's state
  (incl. this arrival's chance rolls), so rebuilding the page on load gives the same page.
- **Loading**: `Main.load_game()` → load scene → `Story.restore(save)`, which rebuilds owners, then enters the top page without running its
  arrival again (no new chance rolls, no visit counted twice).
- **Randomness**: `GameRandom` (`dice/game_random.gd`, static, no dependencies — `DieType` is preloaded by `Rules`, so the `DiceRoller`
  autoload couldn't own it): one `RandomNumberGenerator` for `DieType.roll`, `Story.chance_roller` and `MarkRandomFacesModifier`.
  `Story.start_adventure` starts a new sequence; seed in the journal, `state` in the save. Character creation rolls before that (its
  results are saved by value). Tests keep putting fixed results in as now.
- **Loading UI**: a list of runs (slots) on the title / main scene: continue one, or start a new run.

## Open
- Journal entry types: final list while building step 3.
- Where the run list lives (main scene has no title screen yet).
- Delete old runs from the list?

## Steps
1. ~~`ResourceId` helper (from `AdventurePlayFrom`), unit tests.~~ Done.
2. ~~Seeded RNG (`GameRandom`); dice, chances and marked faces use it.~~ Done.
3. ~~`GameLog` (debug builds; Godot's file logging writes it to disk).~~ Done.
4. `StoryJournal`; `Story` writes entries; visit/decision counts from it. Tests: counts unchanged.
5. Snapshots per owner + `SaveGame` (version, adventure id, RNG, journal); round-trip unit tests per owner; refusing unknown ids.
6. `Story.restore` + `Main.load_game`; autosave at safe points to the run's slot. Integration test: save on a page, load, same page and state.
7. UI: list of runs, continue / new run.
8. Later: saving in fights, debug panel.

## Log
- 2026-11-03: plan started; state inventory and options.
- 2026-11-03: chose C; no fight saves; slot per run with autosave; refuse to load on missing ids; disk log in debug builds; seeded RNG now.
- 2026-11-03: step 1: `ResourceId` (`of` / `find`); `AdventurePlayFrom` writes ids instead of [file, id] pairs. Tests: `resource_id_test.gd`.
- 2026-11-03: step 2: `GameRandom` (static, not in `DiceRoller`: load cycle); dice, chance conditions, `MarkRandomFacesModifier` use it; `Story.start_adventure` starts a new seed. Tests: `game_random_test.gd`.
- 2026-11-03: step 3: `GameLog.write` (static, prints; Godot's own `user://logs` files hold it); story start logs adventure + seed.
