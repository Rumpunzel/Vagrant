# Logging and Saving — Plan

Status (2026-11-03): design chosen (option C); steps 1–6 built (`ResourceId`, `GameRandom`, `GameLog`, `StoryJournal`, save data + `SaveGame`, loading + autosave); UI for runs waits (user), F9 continues the latest run, F10 opens the debug panel, on branch `feature/logging-and-saving`. "Decisions" holds what is settled, "Open" what isn't; the log at the end has the history.
Goal: (1) a log of what happens in a story, for debugging; (2) saving and loading a game in progress. Both need the same thing: a clear
list of the runtime state and a stable way to name content (pages, decisions, monsters) outside the running game.

## Decisions
- **Option C**: a story journal (debug log + visit counts) plus snapshots for saving.
- **No saving during fights** for now: no autosave while a fight is ongoing; loading puts one back at the last page before it.
- **A save slot per run, autosaved.** Starting a new run (new character / adventure) makes a new slot; each safe point overwrites it.
- **Refuse to load** if the adventure changed and an id in the **current state** no longer resolves (or the format version is unknown); say what is missing. History (journal, book) doesn't count (user, 2026-11-03): what is gone from it is left out, so editing the adventure while writing it keeps saves loadable.
- **Log to disk only in debug builds** (`OS.is_debug_build()`); the journal itself is always kept (it goes into the save).
- **"Play from here" isn't saved** (no run slot when a story starts on a given page).
- **No UI for saving and loading yet** (later); F9 (debug) continues the latest run.
- **Seeded RNG now**: one RNG for dice and chance rolls, its seed and state in the save and the log. Cosmetic randomness (roll sounds) stays
  on the global one, so it doesn't shift game results.

## Story book history
Decided (user, 2026-11-03): the book keeps the last **5** entries when a new page is entered; scrolling up just loads older ones (5 at a
time, nothing trimmed while browsing); entering a new page trims back to 5. Old entries are an **exact reconstruction**, from data.
- **The book records what it is told** (option B): a `PageRecord` (`game/story_book/page_record.gd`) per page: title, text and choice
  texts **as shown** (they depend on the state back then; recomputing would need that state), choice icon (id), colour, which was taken,
  backgrounds (ids), injuries shown, what was picked mid-exchange, the outcome typed. `StoryBook` fills it as `Story` calls it and keeps
  every left page's record (`_records`); `StoryEntry.show_record` builds a past entry from one (no typing, no fading; `DialogButton.show_record`).
- **Mid-fight panels** stay as they are while open; once committed, the page shows (and keeps) what was picked instead (`show_pick`,
  `Story._describe_commit`). The user reworks the fight panels later.
- **Dice** (option (i)): each dice widget saves its own final look as data (`get_record`) and shows such a record again (`show_record`):
  `BreathDiceSelection` (portrait, request text, result line, weapons, stance, Nerves target), `BreathDiceSelectionButtons` → groups →
  `BreathDieSelectionButton` (die type, count, exhausted; each button's face, colour, selected, lost), `WeaponSelection` (each option as
  shown, which was picked), `StanceSelection` (attribute and its text), `DiceLogEntry` (its text). The book takes it when the page is left
  (`StoryEntry.get_dice_record`); a die button keeps its face from the moment it gets it (its display waits a random moment). Rebuilt
  collapsible containers set `starts_opened` too: their `_ready` opens or closes them deferred. (ii), rebuilding the request/result
  objects from character snapshots, was dropped: fights would need the monster and the exchange too.
- **Saved** with the run (`Story.get_save().book`, the pages before the current one); a loaded run shows its last pages again.
- **Scrolling**: at the top (scroll bar reaching 0, or the wheel turned up when it can't scroll) `show_older_pages` adds older entries
  above; `AutoScrollContainer.shift_vertical` keeps what was in view where it was.

## Where state lives now
| Owner | State | Notes |
|---|---|---|
| `Story` | `_adventure`, `_page_stack`, `_host`, `_location`, `_encounter`, `_entered_area` / `_first_time_in_area`, `_areas_been_in`, `_chance_rolls`, `_forced` / `_arrivals_while_forced` | Keys are `AdventurePage` objects |
| `Story.journal` | `StoryJournal`: entries in order, visit and decision counts | Replaced `_page_log` / `_decision_log` (only their counts were read) |
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
- **Journal** (`story/story_journal.gd`, `Story.journal`): `entries: Array[Dictionary]` of plain values and `ResourceId`s, each also
  written to `GameLog` as a readable line ("entered "Ruin" (uid://…)"). Entry types: `start` (adventure, seed), `enter` (page), `choose`
  (decision), `roll` (decision, attribute, dice, outcome, margin; not fight rolls), `chance` (condition, came_up), `stage` (subject, track,
  stage), `move` (encounter, places), `exchange` (fight decision, number, outcome). `StoryWorld` emits `stage_set` / `moved`, the journal
  watches it (`Story.world`'s setter). Also `injury`, `breath_lost`, `breath_caught` (by actor name; `watch_actor`, once per actor: the
  protagonist, and each monster as `Story.get_monster` hands it out), and `load` (run). The `exchange` log line also tells the exchange's
  paragraphs as plain text. Counts are kept by object for the running story (test resources have no id); a loaded save rebuilds
  them from the entries.
- **Game log**: `GameLog.write(category, message)` (`custom_nodes/game_log.gd`, static, no dependencies) prints "HH:MM:SS category: …"
  in debug builds only. No own file: Godot's file logging (on by default) already writes stdout and the engine's errors to
  `user://logs/godot*.log`, the last few runs. No levels until something needs them.
- **Debug panel** (autoload `DebugPanel`, `game/debug/debug_panel.gd`, debug builds only, F10): in a `PopoutWindow` (pops out into
  a native, resizable window). A `LogBuffer` (`custom_nodes/log_buffer.gd`, a `Logger` added with `OS.add_logger`, locked since Godot
  calls it from any thread, keeps the newest `LIMIT` lines) and the running story's journal feed the Log tab. Journal entries are drawn
  from their data (`StoryJournal.written`), not from their log lines (those are skipped): an icon per kind (page entered, choice, chance,
  roll, stage, move, injury, breath lost / caught, exchange with its text indented), names as links, numbers bold, outcomes coloured. Other
  lines (engine messages) dim, warnings yellow, errors red, "At: …" indented; each line with the time it came in; a filter and Clear.
  Journal entries keep everything they need for that (`exchange`: both sides, `told`; `roll`: the attribute's id). The State tab (every half second), compact (user): one dim line run · saving · seed; Story rows only
  where there is something (page at location · area entered; event host · encounter; way back; chances); the protagonist (origins
  beside the name; scores in one row; breath dice incl. spent and exhausted, and injuries, in one row; gear and items inline); the world
  only once something changed (stages, moved encounters); monsters met one row each (breath, injuries, beaten / dead, where from). Built from
  `Story.get_save()` (works any time; `SaveGame.capture` checks `can_save`) and the live protagonist; content named by
  `StoryJournal.label` (shared with the log).
- **Links to the editor**: script paths (with a line) and content IDs are links in both tabs. `GameDebuggerLinks.open` sends
  `vagrant:open` over the debugger connection (`EngineDebugger`, only when run from the editor); the `game_debugger` editor addon
  (`EditorDebuggerPlugin`, `GameDebuggerCapture`) opens a script at its line, or a resource in the Inspector. `Story.start_adventure` logs the adventure and seed; the journal will write each entry.
- **Snapshots**: each owner saves its own state as plain values and ids (`get_save()`) and takes it back (`restore(data)`, on a fresh
  object): `Actor` (breath dice, injuries, gear's marked faces and ruined, by profile with their marks (by index for older saves), `Character` (+ exhaustion,
  items, last chosen attribute; `Character.restore_profile` puts what character creation chose — name, title, portrait, rolled dice,
  origins — into a copy of the adventure's protagonist), `Monster` (+ incapacitated, dead), `Monsters` (owner, location, profile, index,
  state), `StoryWorld` (stages, places; restoring emits nothing), `StoryJournal` (entries; counts rebuilt). `Story.get_save()` collects it
  all with its own state (page shown, page stack, host, location, encounter, area, chance rolls, forced) and `GameRandom`'s seed and state
  as text (JSON numbers are floats); only when `Story.can_save()` (not in a fight exchange, `EventQueue.is_idle()`, nothing pending).
- **`SaveGame`** (`story/save_game.gd`): run (slot name, from the start time), `story` data, `saved_at`; `write()` / `read(run)` JSON in
  `user://saves/<run>.json` with a format `VERSION`; `get_problems()` lists every id that no longer resolves (or "another version").
- **Safe points / autosave**: when a page is shown with nothing queued and no fight ongoing. The snapshot holds the shown page's state
  (incl. this arrival's chance rolls), so rebuilding the page on load gives the same page.
- **Autosave**: `Story.run` names the slot (`Main` gives each new story one, `SaveGame.start_run()`: the start time; empty in tests);
  each page entered queues `_autosave` deferred (the event entering it is still running), which saves if `can_save()`.
- **Loading**: `Main.continue_run(run)` reads the save, refuses (warning with the reasons, returns null) if `get_problems()` finds any,
  else loads the Story scene and calls `Story.restore(adventure, run, data)`: world, protagonist (a copy of the adventure's protagonist
  with what creation chose put back), monsters, Story's own state, then `GameRandom`'s seed and state (after the character is made,
  since handing out gear may roll). The saved page is entered again, so its texts are as on arrival: the journal is restored without
  its last entry (that arrival), a `load` entry is added, entering adds the arrival back. Chance rolls are restored, so nothing rerolls.
- **Randomness**: `GameRandom` (`dice/game_random.gd`, static, no dependencies — `DieType` is preloaded by `Rules`, so the `DiceRoller`
  autoload couldn't own it): one `RandomNumberGenerator` for `DieType.roll`, `Story.chance_roller` and `MarkRandomFacesModifier`.
  `Story.start_adventure` starts a new sequence; seed in the journal, `state` in the save. Character creation rolls before that (its
  results are saved by value). Tests keep putting fixed results in as now.
- **Loading UI**: a list of runs (slots) on the title / main scene: continue one, or start a new run.

## Open
- Sometimes the game hangs right at start with "ERROR: BUG: Unreferenced static string to 0: …" (Godot's own message; seen in about 1 of 3 runs on 2026-11-04, also on older commits of this branch): looks like a race in Godot while scripts compile on two threads (`Files.load_async` loads scenes on a background thread). Not looked into yet.
- Runtime-made resources in saved places have an empty id and come back as null; fine for real content (all files), checked by step 6's test.
- Where the run list lives (main scene has no title screen yet).
- The debug restart (Escape) starts a new run (a new slot).
- `Main.continue_run` is not tested end to end (scene change); check by hand with F9.
- Old runs pile up in `user://saves` (one per new game / Escape restart); deleting comes with the UI.
- Delete old runs from the list?

## Steps
1. ~~`ResourceId` helper (from `AdventurePlayFrom`), unit tests.~~ Done.
2. ~~Seeded RNG (`GameRandom`); dice, chances and marked faces use it.~~ Done.
3. ~~`GameLog` (debug builds; Godot's file logging writes it to disk).~~ Done.
4. ~~`StoryJournal`; `Story` writes entries; visit/decision counts from it.~~ Done.
5. ~~Snapshots per owner + `SaveGame` (version, adventure id, RNG, journal); round-trip unit tests per owner; refusing unknown ids.~~ Done.
6. ~~`Story.restore` + `Main.continue_run`; autosave at safe points to the run's slot.~~ Done. Test: `tests/integration/story_save_test.gd`.
7. Later (user): UI, a list of runs, continue / new run. For now F9 continues the latest.
8. ~~Debug panel.~~ Done. Later: saving in fights.

## Log
- 2026-11-03: plan started; state inventory and options.
- 2026-11-03: chose C; no fight saves; slot per run with autosave; refuse to load on missing ids; disk log in debug builds; seeded RNG now.
- 2026-11-03: step 1: `ResourceId` (`of` / `find`); `AdventurePlayFrom` writes ids instead of [file, id] pairs. Tests: `resource_id_test.gd`.
- 2026-11-03: step 2: `GameRandom` (static, not in `DiceRoller`: load cycle); dice, chance conditions, `MarkRandomFacesModifier` use it; `Story.start_adventure` starts a new seed. Tests: `game_random_test.gd`.
- 2026-11-03: step 3: `GameLog.write` (static, prints; Godot's own `user://logs` files hold it); story start logs adventure + seed.
- 2026-11-03: step 4: `StoryJournal` replaces `_page_log` / `_decision_log`; entries for start, enter, choose, roll, chance, stage, move, exchange, each logged. `StoryWorld` signals. Tests: `story_journal_test.gd`; tests that filled `_page_log` use `journal.enter`.
- 2026-11-03: step 5: `get_save` / `restore` on `Actor`, `Character` (+ `restore_profile`), `Monster`, `Monsters`, `StoryWorld`, `StoryJournal`; `Story.get_save` / `can_save`; `EventQueue.is_idle`; `SaveGame`; `ResourceId.of_each` / `find_each`. Tests: `save_state_test.gd`.
- 2026-11-03: step 6: `Story.run`, autosave on each page (deferred, if `can_save`), `Story.restore`, `Main.continue_run` (refuses on problems), journal `load` entry. Tests: `story_save_test.gd` (go on from the save: page, way back, counts, character, random numbers).
- 2026-11-03: "Play from here" makes no run slot; F9 continues the latest run (`SaveGame.get_runs`); journal watches actors (injuries, breath) and logs exchange texts.
- 2026-11-03: debug panel (F10): Log tab from a `Logger` (`LogBuffer`), State tab from `Story.get_save`. `StoryJournal.describe` public. Tests: `debug_panel_test.gd`.
- 2026-11-03: debug panel v2: `PopoutWindow`, coloured log, links that open in the editor (`game_debugger` addon), State tab in sections with icons; `StoryJournal.label` names content for both. Checked by recording frames (`--write-movie`); the editor links not yet by hand.
- 2026-11-03: debug panel log v2: journal entries drawn from their data (icons, links, bold numbers, coloured outcomes) instead of the "story" text lines, which told nothing a line couldn't show better; `StoryJournal.written`, `LOG_CATEGORY`, `to_plain_text`.
- 2026-11-03: story book history, stage 1: `PageRecord`, `StoryBook` keeps 5 entries, builds older ones on scrolling up, saves and restores them; commit panel leaves its pick. Dice records still to do. Tests: `story_book_history_test.gd` (3).
- 2026-11-03: story book history, stage 2: dice records (`get_record` / `show_record` on the dice widgets). Test: dice built again as they were (1). Checked on screen by recording frames.
- 2026-11-03: State tab compacted; empty rows and sections left out.
- 2026-11-03: debug panel cost: `Story.get_state()` (the story's own place, cheap) split out of `get_save()`; the State tab reads it, the world, the monsters (`Story.get_monsters`) and `Actor.get_injuries()` instead of the whole save (journal, book).
- 2026-11-03: tooltips in every window: tooltips_pro's manager puts mouse tooltips in their trigger's window (fixes popped-out character sheets too); `MetaTooltipTrigger` for links; the debug panel's links preview their content (background / portrait / icon, name, first line). Tests: `tooltip_window_test.gd` (2).
- 2026-11-03: saves are written next to the slot and then renamed over it (a crash mid-write keeps the last save); autosave writes on a worker thread (`SaveGame.write_in_background`, one at a time; `read` and leaving the story wait for it).
- 2026-11-03: loading is lenient about history: `SaveGame.HISTORY` (journal, book) isn't checked; the journal skips entries naming gone content, the book shows what is left.
- 2026-11-03: `ResourceId.find` indexes a file's inner resources once (by the loaded file, weak references; a miss indexes again, for files edited since): loading a long run no longer walks the adventure files thousands of times.
- 2026-11-03: `Story.start_adventure` and `Story.restore` share `_begin` (adventure, world, protagonist, journal watching); starting sets the seed before it (gear may roll), restoring sets the saved random state after.
- 2026-11-03: rebuilt book entries turn past with `PageEntry.become_past(true)` (no fade) instead of overwriting the fade exports.
- 2026-11-04: background saving taken out again: the game hung while recording frames, with an engine error about threads; the cause turned out to be Godot's movie mode (it hung on older commits too), but a big save (≈600 pages, 1.4 MB) takes ~45 ms written normally, so saving stays synchronous and simple.
- 2026-11-04: debug panel Runs tab: save now (also makes "Play from here" a run), restart with a seed (`GameRandom.next_seed`, `Main.restart_story`; Escape uses it too), bug report (`user://bug_reports/<time>/`: save as it is now, also mid-fight, and the log; opened, path copied), saves folder, runs newest first with their page, continue / delete (not the running one). Journal: a monster's death (`Monster.died`) and resting (exhaustion gone); items don't change in stories yet.
- 2026-11-04: Runs tab rows name the saved protagonist; hovering the name shows it in a tooltip (portrait, name and title, origins, rolled scores, breath dice, injuries, items; `_breath_icons` shared with the State tab).
- 2026-11-05: items change in stories now (`Items-Plan.md`): gear is saved by its profile (`ResourceId`) plus marks, no longer by its place in the profile's lists (older saves still load by place); `StoryWorld` saves the loot left per encounter (`loot_left`, none in older saves); journal `gained` / `lost` (actor, item, count), shown in the debug panel; loot pages are in-between pages like a fight's exchanges (no saving on them).
- 2026-11-06: the game hung now and then on starting (seen in the editor's runs): `Main.enter_story` loaded the Story scene on a thread while the main thread loaded character creation, which shares scripts and resources with it, and Godot's loader deadlocked (the log ends at loading character creation, no CPU used). The Story's threaded load now starts once character creation is loaded.
- 2026-11-07: past book pages keep the mouse: their controls are made inert (`InertControls`: no clicks, focus, keys or editing; hover, tooltips and the wheel work), and the hover highlight asks the window which control is under the mouse (`mouse_entered` / `exited` skip the page when the mouse enters straight onto a child, checked in Godot 4.6).
