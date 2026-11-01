# Adventure Editor — Plan

Status (2026-11-01): built through encounters, one event screen and the cleanups on branch `refactor/encounters`; see "Built" for what exists,
"Open" and "Later" for what doesn't. The log at the end has the history.
Goal: a visual editor for one `Adventure` as a main-screen editor tab (next to 2D / 3D / Script).

## Decisions
- **Main-screen plugin.** Opens by double-clicking an `Adventure` `.tres` (`_handles` / `_edit`), plus a picker in the tab.
- **One adventure per editor.** Map pages are found by walking links from `starting_page`, plus the encounters listed on the adventure.
- **Graphs only where the content is a graph of links** (the map; the pages behind an event). Collections and orders are lists, properties the
  Inspector (with a plugin for UID fields). Text is edited in the Inspector, not in cards.
- **Links stay `AdventureTransition`s**, and back-pointers (to encounters and locations) go by UID: Godot can't load files that reference each
  other in a loop, and nothing can point inside another file.
- **The world is locations and encounters.** A location shows its own events and those of the encounters that can be there, in its order;
  an encounter's story is in its stage tracks, its monster's body in runtime state (can fight / beaten / dead).
- **Layout side file** per adventure (`<adventure>.layout.tres`): node positions, links to placed special nodes, page graphs' heights and views.
  Game `.tres` stay untouched by moving nodes.
- **Edits** go through `EditorUndoRedoManager` and the editor's own saving, so UIDs survive (scripted `ResourceSaver.save()` outside the editor
  drops them); new files and deleting are part of their undo step (deleted files go to the system trash).
- **Icons wherever possible** (user): menu items get one by the words in them (`AdventureActionMenu`), buttons by what they do.
- **Reconsider critically** (user): after each step an honest check whether it is still the right way; doubts go to "Open".

## Design
| File | Owns |
|---|---|
| `adventure_editor_plugin.gd` | The main-screen tab "Adventure": handles `Adventure`, remembers the open one, passes its undo manager, reports and saves unsaved changes, adds the UID inspector |
| `adventure_editor.gd` / `.tscn` (`AdventureEditor`) | State (adventure, map model, problems, layout, edits, every event) and the tabs: Map (graph + event sidebar), Location, Events (event list, "At:" picker, the event screen), Problems; Find…; rebuild on edits and Inspector changes; "Play from here" |
| `adventure_editor_actions.gd` (`AdventureEditorActions`) | Everything made or deleted through a dialog: new locations, events, options, encounters (monster template), offering events made already, deleting; owns the dialogs |
| `adventure_edits.gd` (`AdventureEdits`) | Changes ([resource, property, value(, file)]) as undo steps, new files and deleting in the same step, unsaved files, saving |
| `adventure_makers.gd` (`AdventureMakers`) | New things: pages, decisions, events, scenarios, encounters (with an NPC's Storyline or a monster's ambush), tracks, conditions, effects, locations, areas, links, and where their files go |
| `adventure_event_editing.gd`, `adventure_map_editing.gd` | Changes as data: listing events, forgetting what is deleted (also UID back-pointers), putting / removing / placing at locations, unlinking; file and reference helpers |
| `adventure_graph.gd` (`AdventureGraph`) | Map model: pages, areas, links (also through events), event hosts, encounters and the locations they could show on, titles |
| `adventure_event_graph.gd` (`AdventureEventGraph`) | One event's pages: outlets and ports, outcomes, exits, depths; texts for checks, effects, conditions and what Hide flags hide |
| `adventure_location_overview.gd`, `adventure_location_view.gd` | The Location tab: what can happen at a location in its order (own events, encounters there / near / anywhere / that can come), banner with background and ambience, editing |
| `adventure_storyline.gd` (`AdventureStoryline`) | An encounter's story: where its events can happen (stages, body), where their decisions lead, toggling, adding tracks and stages |
| `adventure_event_screen.gd` (`AdventureEventScreen`) | The event screen: a plain event as one section, a scenario or encounter as a foldable section per option with its story columns and track bars; each section's page graph, its height handle |
| `adventure_graph_view.gd` / `adventure_card_view.gd` / `adventure_event_view.gd` / `adventure_map_view.gd` | Graph views: shared nodes, lines, menus, problems, tidy; page and decision cards with condition and effect chips; an event's page graph (Host / Previous in its toolbar); the map (area frames, links) |
| `adventure_problems.gd` (`AdventureProblems`) | The problem list, also events that can never show |
| `adventure_uid_inspector.gd` (`AdventureUidInspector`) | UID fields in the Inspector as resource pickers with titles |
| `adventure_layout.gd` (`AdventureLayout`) | The side file and its keys (event graph keys still name the event twice, from when a view showed several events, so saved positions stay valid) |

## Built
- **Map:** areas as frames, locations, links (dashed through events), unreachable pages faded; link / unlink, new location and area, Alt+drag out
  of a frame, drop events, encounters, monster profiles and images; delete; Tidy; play from here; Find; ★ starting page (set from the menu);
  exits on each node (click: text and first-time text; new links ask for them; + way back where there is none); ▶ ambience on locations and
  areas (one at a time); area texts from the frame's menu; 🎲 on events that happen by chance.
- **Location tab:** banner (background, ambience), text, sections in the location's order with ▲ ▼, + event, + encounter, ✕, can come here.
- **Event screen:** one per event; scenarios and encounters as foldable sections with their page graphs (height handle, scroll and zoom kept),
  pick first / every, + Option, Add event…; encounters with track bars (+ stage, + track), the Body bar, "In" (click to change) and "Leads to";
  picking a stage dims what can't happen then and marks what leads into it.
- **Page graphs:** pages, decision cards (choices, fights, saves with their outcomes), condition and effect chips at the start of their
  transition, Host / Previous location, exits; links by dragging ports, new pages on empty space.
- **Data:** locations, events, scenarios (first / all), encounters (places, stage tracks, where, only at), stage / move / kill effects,
  stage / place / monster / chance conditions (chance: rolled once per arrival at a location), one-off fights, the problem check;
  area texts on entering an area; events' text and decisions layering (adds / replaces the location's / only this); "no rest here" on pages
  and events (toggled on the event node).

## Open
- [ ] Effects: if chips at the start of a transition aren't clear enough, try a node in the path for an outcome with effects (user to judge)
- [ ] Monster template stage names and the template idea in general (user, later)
- [ ] Map placement is a plain grid per area until nodes are moved; judge once there are more locations (user)

## Later
- Encounter templates (several wolves), with the party / carried by, item encounters, loot ("Looted" after Dead, loot tables; needs items),
  roaming by itself (random, routes, time of day)
- Fight decisions with input ports for who takes part; fights against several opponents (needs the fight UI first)
- Portals: a link into another area ends in a small portal node inside the source frame
- The location tab growing into a full location editor

## Log
- 2026-10-25: plan agreed (main-screen tab, one adventure, `AdventureTransition` kept, location = page with area, events as shared attachments, side layout file, v1 view only, portals later)
- 2026-10-25: open points settled (dashed lines through events, area-less pages outside frames, `_background` made public, `CLAUDE.md` update in v1)
- 2026-10-25: v1 built: `_background` → `background`, plugin, `AdventureGraph` (11 unit tests), view with frames / nodes / event cards / dashed event links, layout file, `CLAUDE.md` updated
- 2026-10-25: all `AdventurePage` exports made public (content `.tres` keys and tests renamed); `AdventureGraph` reads them directly
- 2026-10-25: area frame margin 40 → 80, untitled pages show their capitalized file name
- 2026-10-25: events tab (v1.1): `AdventureEventGraph` (5 tests), event hosts in `AdventureGraph` (1 test), views split into `AdventureGraphView` / `AdventureMapView` / `AdventureEventView`, `AdventureEditor` is the root now; event cards open the event instead of the Inspector (selecting the event node does that)
- 2026-10-25: v1.2 discussed: `AdventureEventScenario` (shows one of its events), "↺ Host" reference, monsters per host or shared, "At:" host picker in the events tab instead of a floating window
- 2026-10-25: v1.2 engine: `AdventureEventScenario` (+ `AdventurePage.resolve_event`), `AdventureHostReference` + `Story.get_host()`, `generic` events (monsters per host), Lurker moved into `events/lurker.tres` with host references; tests: scenario suite (8), monsters (1), story (2), Lurker content updated
- 2026-10-26: v1.2 editor: `AdventureEventOverview` (7 tests), frames per scenario option and sub-event, "↺ Host" nodes, "At:" picker with hiding / monster info, event tree list, `AdventureCondition.describe()` (conditions are `@tool` now); `get_targets_by_property` → `get_references` (keeps host references); wrapping labels got a width (nodes grew tall)
- 2026-10-26: event view shows more: fights and saves as check nodes with fixed outcomes (Won / Lost / Fled / Draw, Success / Failure; settles the outcome order), whole page text, consequences per outcome, text-based titles for pages stored inside other files; `AdventureConsequence.describe()`. Scenario selection visuals tabled until conditions are editable
- 2026-10-27: manual checks done (user); v2 slice 1 (map editing) agreed: link / unlink / new location / frame drop, undo, unsaved changes saved through the plugin's hooks, Inspector for content
- 2026-10-27: v2 slice 1 built: `AdventureMapEditing` (5 tests), `AdventureTransition.leading_to`, map view edit requests, new-location dialog, undo through `EditorUndoRedoManager`, unsaved changes through the plugin hooks + Ctrl+S, placed-but-unreachable pages (1 test)
- 2026-10-27: map editing checked by user. Locations can be dragged out of areas (and into others): frames don't shrink while dragging, the frame under the center decides. File names: runs of non-letters/digits become one "_" (Unicode letters kept, empty → `untitled`)
- 2026-10-27: the frame-shrinking change didn't help (frames grow with attached nodes, which is wanted); replaced by Alt+drag to let a location go of its frame
- 2026-10-27: v2 slice 2 (event editing) agreed: links / new pages / new decisions in the event graph, new events and scenarios from the map, pages inside the event's file (cycles refused), fights and saves start empty, putting events on more locations later
- 2026-10-27: v2 slice 2 built: `AdventureEventEditing` (7 tests), event view link / unlink / drop-on-empty / page menu, map location menu (new event, scenario), `AdventureNameDialog`, shared context menu in `AdventureGraphView`, changes mark their owning file unsaved, layout keys inline resources by their in-file ID
- 2026-10-28: after the manual check: decisions as cards inside page cards (fight / save colored with icons, outcome ports inline, reorder / remove, add bar), host node always shown and colored, losing pages stored inside a file refused (explicit "Delete page" instead, user's choice over a hidden list of unlinked pages), menu icons, event view stacks nodes by real height
- 2026-10-28: card selection, outcome colors, automatic "Turn back.", back steps, effect tags with "+ effect" (2 tests); proposed "↶ Previous location" as a page reference with a sidebar of special nodes
- 2026-10-28: `AdventurePreviousLocationReference` + `Story._go`, sidebar with draggable Host / Previous location (`AdventureSpecialButton`), several copies per frame (`AdventureLayout.special_links`), Fled content moved over; tests: story (1), Lurker flee continues (1), special references (1); fixed a restack touching freed nodes when the view is shown twice in one frame
- 2026-10-28: conditions and scenarios agreed: switch node per scenario, condition tags with quick picks for fights' monsters, dotted lines from monster conditions to their fight, new options as files
- 2026-10-29: conditions and scenarios built: switch nodes (overview `switches`, no more numbered frame titles), condition tags with type list and monster quick picks, dotted condition → fight lines (dashed layer drawn above nodes, from the facing side, redrawn when ends move inside their node), options added as files in `events/`; tests: overview (2), editing (2)
- 2026-10-29: automatic "Turn back." row is linkable (becomes a "Continue." choice); participants idea noted
- 2026-10-29: automatic turn back colored like the host; agreed: straight map lines, adding existing events from a list, nearby events (own conditions, reach 1 / n / 0 = area)
- 2026-10-29: built straight map lines (`_add_line`, edge points, arrows), existing events (menu of known + `events/` files + file dialog, remove from here), nearby events (`AdventurePage.nearby_events` / `nearby_reach`, `find_nearby_events`, `Story.get_nearby_events`, `AdventurePageReference.load_page`), Hearing Eleanor moved into The Mysterious Woman; tests: nearby (8), Eleanor content (1); Lurker test accepts the automatic turn back (user removed Lost / Draw "Continue.")
- 2026-10-29: user meant a visible event list on the map: added the map's event sidebar (drag onto a location; the Map tab is now graph + sidebar, `_map_tab`)
- 2026-10-29: housekeeping (split, test content removed, committed), problems tab (6 tests), play from here (`AdventurePlayFrom`, `Story.start_adventure` page / host; 5 tests); tried in a headless run: the start file is taken and the game starts (character creation first for the test adventure)
- 2026-10-29: icons on every context menu item
- 2026-10-29: agreed: problems on nodes, drag from the FileSystem panel, search, tidy; not wanted: stand-in character, own text editing
- 2026-10-29: built problems on nodes (`problems` on the views, `_mark_problems`), drag from the FileSystem panel (`background_dropped`, events onto locations), Find… (filters the Events list and sidebar, Enter jumps, Ctrl+F), Tidy (forgets a graph's positions but placed special nodes')
- 2026-10-29: manual checks done (user): "works well enough"
- 2026-10-29: idea noted: input ports on fights for who takes part
- 2026-10-29: cleanup agreed (A, B + C, E; D, menu entries as objects, not now)
- 2026-10-29: A done: `AdventureDecision.Outcome`, `get_outcomes` / `get_reference` / `get_consequences_of` / `get_page_references`, dice `get_outcome(success)`, fight `get_fight_outcome`; `Fight`, `StorySaveDecision`, `AdventurePage.get_held_pages` and the editor use them (3 tests); Lurker test follows the user's Draw → Previous location
- 2026-10-29: B + C + E done: `AdventureEdits` (5 tests; caught `UndoRedo.add_do_method` taking a Callable where the editor's takes object + method), one `changes_requested` signal on all views (the map builds link / unlink / area / event / background changes itself), root wiring grouped, keys in `AdventureLayout` (1 test), event files scanned once per rebuild, `AdventureTransition` uses `load_page()` in the editor, nearby = plain links documented
- 2026-10-30: user tried undo (works, not for moving / adding); built deleting with the system trash, undoable adding, nearby `stays in area`; tests: edits (4 more), forgetting (2), nearby (1)
- 2026-10-30: editor warnings fixed (`owner` / `reference` locals shadowing Node / RefCounted members renamed to `holder` / `link`, Variant casts; `AdventurePlayFrom.take()` returns an `AdventurePlayFrom` with typed fields instead of an Array); layout keys of deleted files are skipped (unknown UIDs made `ResourceLoader.exists` error) and forgotten on deleting
- 2026-10-30: model rethought with the user: locations and encounters (stage tracks, where, scenarios first / all, order on the location); steps 1–6 agreed
- 2026-10-30: step 1 built: the page types split, Story / editor / tests retyped (map nodes that are plain pages get no event actions; event files that are plain pages no longer show as events)
- 2026-10-30: step 1 committed; step 2 built: own scenarios on locations, `pick`, `resolve_events`; editor lists events through `AdventureGraph.get_listed_on` and `AdventureEventEditing.get_changes_listing`; tests: `TestAdventures` helper, pick all (1), listing (1)
- 2026-10-30: step 3 designed with the user: UID back-pointers, encounters in all their possible places until contact, own events as a slot in the location's order, first-visit text, contact by a move consequence
- 2026-10-30: step 3 built: `AdventureEncounter`, `AdventureStageTrack`, `where` / `only_at`, `order`, `first_description`, stage condition, stage and move consequences, `StoryWorld`; `nearby_events` gone; Eleanor moved to `encounters/eleanor/` (greeting her places her and sets Met); editor: encounters in the event list, faded "could be here" cards on the map; tests: encounters (11), Eleanor content (3), first visit (1)
- 2026-10-30: step 4 built: fights name encounters, one-off fights for `enemies`, Lurker as an encounter with stages; tests: Lurker content and story reworked, monsters per encounter / per location (1)
- 2026-10-30: step 5 built: place condition; tests: place condition (1), location stages (1)
- 2026-10-30: step 5 committed; 6a built: making and placing encounters; test: new encounters (1)
- 2026-10-30: 6a committed; 6b built: location tab; `AdventureLocation.get_slots` (the own events' slot in the order also without own events); tests: location overview (5)
- 2026-10-30: double-click opening waits for the mouse button (no stuck drag); 6c built: storyline view; tests: storyline (3)
- 2026-10-31: graphs reconsidered with the user (lists and tables where content isn't links); 1 built: location tab editable; test: putting / placing (1)
- 2026-10-31: location tab: banner with the background (the area's if it has none), title and area over a fade, the image dimmed behind the tab, ▶/■ for the ambience (stops when the tab is hidden), its text (and first-visit text) under the banner
- 2026-10-31: banner buttons fixed; 2 built: storyline table (ticks, + Track / Stage / Event, typos marked red), the storyline graph view replaced; tests: storyline table (4)
- 2026-10-31: user: storyline table not intuitive (stages look like flags), back to the drawing board later; 3 built: options list for scenarios and encounters, switch code gone; tests: overview reworked
- 2026-10-31: 4 built: UID fields in the Inspector; test: fields and UIDs (2)
- 2026-10-31: storyline redesign, first try: one screen (no toggle): an encounter's options list gets a bar per track with stage chips (picking one dims what can't happen then, marks what leads into it), "Happens in" (click: tick stages) and "Leads to" (decision → stage, edited in the pages); table and storyline view gone; tests: storyline (4)
- 2026-10-31: user: fold the page graphs into the encounter screen, show stage changes in the graph; reconsider critically and often; 1 built: foldable sections with graphs
- 2026-10-31: 2 built: stage end nodes in the graphs; loot idea noted
- 2026-10-31: user: "beaten" can drift from the monster's real state; proposal noted under To reconsider; 3 built: one event screen for every event, the separate event graph gone
- 2026-10-31: body vs. story done: monster condition and kill consequence back, about encounters; Lurker and template without State track; tests: body (1), Lurker content reworked
- 2026-10-31: event list without options (they are on the screen; listed while finding); a monster's body on the screen like a track (Body: can fight / beaten / dead; won fights → beaten, kills → dead) and as end nodes in the graphs; test: body (1)
- 2026-10-31: no frames in page graphs; effects as chips at the start of their transition, end nodes gone
- 2026-11-01: never-shows problem check; tests: stages, monsters (2), content has none (1)
- 2026-11-01: Host / Previous in the sections' title bars (sidebar gone); a height handle under each graph
- 2026-11-01: Host / Previous moved into the event graphs' toolbars
- 2026-11-01: icons on the specials, event cards, the map's event buttons, "In …" and "Open its options"; each graph's scroll and zoom kept in the layout (`graph_views`) with its height; tidying a graph forgets both
- 2026-11-01: cleanups: docs, hiding text by order, overview folded into the event view, frames to the map, AdventureEditorActions and AdventureMakers split out, this plan condensed (history stays in the log)
- 2026-11-01: chance condition (1 in N, rolled once per arrival, hidden); the Lurker's ambush starts with the water stirring (1 in 2), "Continue." leads into the fight; tests: chance (1), Lurker content and story reworked
- 2026-11-01: Hide flags replaced by text and decisions layering (adds / replaces the location's / only this; of two "only", the earlier wins); area texts on entering an area (first-time text); the event node previews the page (click a row to show or hide it); "Play from here" forces its event (all conditions met on the first arrival, its scenario picks it) and has ▶ buttons on the event screen's sections and the location banner; tests: layering (4), area text (1), forced (1)
- 2026-11-01: no breath dice left: saves and fights are greyed out (tooltip) and come back after catching breath; with nothing else to do, the first fails at once (generalizes the fight lost on arrival, which moved from `Fight` to `Story`); "no rest here" (`AdventurePage.no_rest`, a page or any event on it) disables catching breath and making camp, set on meeting Eleanor and the Lurker's stirring water; tests: availability (1), no rest (1), greyed out and failing on arrival (2)
- 2026-11-01: a choice's first-time text (`AdventureDecision.first_description`, until the page it leads to was visited, read from the load cache so nothing loads early); map: exits with their texts, linking asks for them, + way back, ▶ ambience, ★ starting page, area texts dialog (`AdventureTextsDialog`), 🎲 on chance events; duplicate decisions are a problem, linking twice adds none; tests: first-time text (1), offered twice (1)
