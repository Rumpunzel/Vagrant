# Adventure Editor — Plan

Status: **v1 + events tab built** (2026-10-25). Waiting on: manual check in the editor by user (see Open).
Goal: a visual editor for one `Adventure` as a main-screen editor tab (next to 2D / 3D / Script), starting as a map of areas and locations.

## Decisions
- **Main-screen plugin.** Opens by double-clicking an `Adventure` `.tres` (`_handles` / `_edit`), plus a picker in the tab.
- **One adventure per graph.** Pages are found by walking links from `starting_page`; areas don't list their pages, so the walk is the only source.
- **Links stay `AdventureTransition`s.** Godot can't load `.tres` files that reference each other in a loop and there is no real way around that; the editor hides the indirection (reads it now, creates it later).
- **No data changes without a good reason.** A *location* is a page with `area` set; no new class for now.
- **Graph:** area = `GraphFrame` (area background dimmed behind it), location = `GraphNode` (its background as a thumbnail), link = connection from a location's decision to the location it leads to. Decisions without a transition (turn back) draw nothing.
- **Events are attachments:** shown as cards on their host location, not as graph nodes. One event can have several hosts (generic encounters; an event that may happen in one of several places, but only once). Later they get their own tab in the editor window, so they stay lightweight on the map.
- **Layout side file** per adventure, next to it: `<adventure>.layout.tres`, node positions keyed by page UID (path for pages without one); frames shrink to fit their locations, so they need no rects. Written on the first move. Game `.tres` stay untouched by moving nodes.
- **Saving edits (v2+)** goes through `EditorUndoRedoManager` and the editor's own saving, so UIDs survive (scripted `ResourceSaver.save()` outside the editor drops them).
- **Links through events** (a location reached only via an event or its inner pages, e.g. Lurker won → Temple Ruin) are drawn as a dashed line from the host location.
- **Pages without an area** stay in the graph, outside all area frames.
- Untitled pages / events show their file name, capitalized (`hearing_eleanor` → "Hearing Eleanor"). Area frames keep an 80 px margin around their locations (Godot's default is 40).
- `AdventurePage`'s exports are public (`title`, `description`, `area`, `background`, `ambience`, `conditions`, `decisions`, `exclusivity`, `events`); the editor reads them directly, the `get_*(story)` methods stay for the resolved, event-dependent values. Today only events set one (Meeting Eleanor, Lurker ambush), locations use their area's, so a location node shows its own background if set, else none (the area's is already behind the frame).
- UI is kept plain; the user styles it by hand later.
- **Icons wherever possible** (user, 2026-10-29): every context menu item gets one by what it does (`AdventureGraphView.MENU_ICONS`; fights, saves and monsters the game's icons).

## Design
| File | Owns |
|---|---|
| `adventure_editor_plugin.gd` | Main screen tab "Adventure": handles `Adventure`, remembers the open one in the editor layout, rebuilds on resource saves; passes its undo manager, reports unsaved changes (`_get_unsaved_status`) and saves them (`_save_external_data`) |
| `adventure_editor.gd` / `.tscn` (`AdventureEditor`, root) | Adventure picker and Find…, tabs "Map" (graph + event sidebar) / "Events" / "Problems", the event list as a tree, "At:" host picker; wiring (`_make_dialogs`, `_connect_views`, `_connect_lists`): every view's `changes_requested` goes to `AdventureEdits`; dialogs for new locations, events, options; offering events; "Play from here"; rebuild on edits and Inspector changes, every event file found once per rebuild (`_all_events`). `setup()` instead of `_ready`, so opening the scene doesn't run it |
| `adventure_edits.gd` (`AdventureEdits`) | **Edits** (unit tested with a plain `UndoRedo`): `apply(changes, action, file)` — [resource, property, value] changes as one undo step, marking the file they are stored in unsaved; `save()`, `has_unsaved_changes()`, `create_file()` (not undone). Works with the editor's `EditorUndoRedoManager` (the plugin's) or an `UndoRedo` |
| `adventure_graph.gd` (`AdventureGraph`) | **Map model** (unit tested): `get_title` (title; untitled: file name, or for a page stored inside another file the start of its text); walks from `starting_page`; `pages` (nodes), `areas`, `links` (`Link.through_event`), `event_hosts` (every event met, with the pages listing it), `get_location_hosts(event)` (map pages it happens on, also through scenarios), `get_top_events()`. `get_references(decision)`: every `AdventurePageReference` property, `transition` first (property list, since decision scripts aren't `@tool` and are placeholders in the editor); host references lead to no page on the map |
| `adventure_event_graph.gd` (`AdventureEventGraph`) | **Event model** (unit tested): `pages` (event + pages behind it, not through nested events), `exits` (locations), `depths`, `leads_to_host`. `get_outlets(page)`: a row per decision (plain: its target / host / back and consequences; fight or save: `to_check`); `get_ports(page)`: what the page's output ports lead to, outcomes inlined. `get_outcomes(check)`: fixed per kind (fight: Won / Lost / Fled / Draw, other dice checks: Success / Failure) with their consequences, other page references after. `describe_check` ("Fight: Lurker", "Save: Nerves 5"), `describe_consequences` (`AdventureConsequence.describe()`, consequences are `@tool` now) |
| `adventure_event_overview.gd` (`AdventureEventOverview`) | **Overview model** (unit tested): `entries` (one per event and per sub-event of the pages inside, recursively, each with its `AdventureEventGraph`, `listed_as`, parent entry and page, the `switch` it is an option of) and `switches` (one per scenario, `outer` for nested ones); texts: conditions (`AdventureCondition.describe()`), what Hide flags hide at a host, monsters shared / per host |
| `adventure_graph_view.gd` (`AdventureGraphView`, abstract) | Shared view: nodes by layout key, frames, dashed links (internal layer above the frames), page content (thumbnail, event cards → `_on_event_card_pressed`), wrapping labels, selection → Inspector, positions → `layout` (`layout_changed`), `scroll_to_nodes`, `focus_node` |
| `adventure_map_view.gd` (`AdventureMapView`) | Frames per area, one port per node, dashed links through events, unreachable pages faded; requests edits (`link_requested`, `unlink_requested` via `right_disconnects`, `location_requested` from the right-click menu, `areas_requested` after a move: Alt+drag lets locations go of their frame, the frame under the center decides) |
| `adventure_event_view.gd` (`AdventureEventView`) | The overview: a frame per entry side by side; page cards with their whole text, decision cards (choice: one port; fight / save: colored, icon, a port per outcome; ▲ ▼ ✕; click → Inspector) and an add bar; a host node per frame; faded exits; info lines on the event node; sub-events dashed from their page. Default places: a column per step, stacked by real height a frame after building. Requests: `reference_requested`, `decisions_requested`, `references_cleared` (delete page); refuses losing pages stored inside the file. Layout keys `<root>/<entry event>/<page or host>`; a switch node per scenario before its options' frames (rows linked to the options, ▲ ▼ ✕, + option); condition and effect tags (`_make_tags`); dotted lines from monster conditions to the fight card spawning the monster |
| `adventure_layout.gd` (`AdventureLayout`) | Side file: positions, links to placed special nodes; builds and recognizes every key: `get_key` (a file's UID, an inside resource's `::id`), `is_location_key`, `get_event_key`, `get_placed_special_prefix` / `is_placed_special`, `get_switch_key`; `get_placed_pages()` |
| `adventure_map_editing.gd` (`AdventureMapEditing`) | **Map edits as data** (unit tested): `make_link` (plain decision + `AdventureTransition.leading_to`), `without_links`, `make_location`, `make_area`, file paths and names |
| `adventure_event_editing.gd` (`AdventureEventEditing`) | **Event edits as data** (unit tested): `get_file_path`, `make_reference` (same file: the page, else `AdventureTransition`), `would_loop` (through pages and events held directly), `is_inside_file`, `find_references_to`, `would_lose_page`, `make_page` / `make_choice` / `make_fight` / `make_save` (with an in-file ID), `make_event`, `get_event_path`; `get_condition_types` / `get_consequence_types` (classes in the project that can be made), `get_type_name`, `make_condition`, `make_monster_condition` (quick picks, `spawned_by` by file, none if it would loop) |
| `adventure_new_location_dialog.gd` (`AdventureNewLocationDialog`) | Title + area (existing or "New area…" by name) |
| `adventure_name_dialog.gd` (`AdventureNameDialog`) | Asks for a name (new events, scenarios) |
| `adventure/adventure_transition.gd` | In the editor loads its page with plain `load()` (`Files.load_async` isn't `@tool` and is for the game's threaded loading) |

## v1 — view only
Shows the map; nothing in the adventure data changes. Moving nodes / frames only writes the layout file. `[~]` = built, only checkable by hand in the editor.
- [x] Rename `AdventurePage._background` → `background` (script + `meeting_eleanor.tres`, `lurker_ambush.tres`)
- [x] `plugin.cfg` + `adventure_editor_plugin.gd` (main screen, handles `Adventure`), enabled in `project.godot`
- [x] Graph model (pure, no UI, unit tested with pages built in code): walk pages from `starting_page` through decisions, events and transitions; collect areas, locations, links, event hosts
- [x] `adventure_editor.tscn` (reuse the stub: `GraphEdit`, frames, nodes) builds the view from the model
- [x] Location node: title, background thumbnail, event cards; pages without an area as the same node outside frames
- [x] Dashed lines for links that run through an event
- [x] Area frame: name, dimmed background, contains its locations
- [~] Click a location / event / area: open it in the Inspector (`EditorInterface.edit_resource`)
- [~] Layout file: load, place new nodes automatically, save on move
- [~] Reload when the adventure or one of its pages changes on disk / in the Inspector
- [x] Update `CLAUDE.md` (addons section still calls `adventure_editor` "just a scene")

## v1.1 — events tab (agreed 2026-10-25, view only)
- Tabs "Map" and "Events" under the adventure picker. Events: list of all events of the adventure (left), graph of the picked one (right). An event card (on the map or inside an event) opens that event there.
- Event graph: the event as first node (listing its hosts), the pages behind it as nodes, the locations it leads to as grey exit nodes (double-click: back to the map, centred and selected). Nested events stay cards.
- One output port per decision outcome, labelled: the decision's text for its transition ("(back)" without one), then "↳ Failure" / "↳ Flee" / "↳ Draw" ... for the other page references.
- Positions in the same layout file, keyed per event (`<event uid>/<page uid>`), so a page shared by two events can sit apart in each.
- [x] Event model `AdventureEventGraph` (pages, exits, depths, outlets) + unit tests; `AdventureGraph` collects events and their hosts
- [x] Views split: `AdventureGraphView` (shared nodes, cards, selection, layout), `AdventureMapView`, `AdventureEventView`; `AdventureEditor` becomes the root (picker, tabs, list, wiring)

## v1.2 — reusable events (done 2026-10-26)
Events should work on any page and name a page or location only when they mean to. Today the Lurker is bound to Temple Ruin three times: Fight won → `temple_ruin`, "Kill the Lurker" → `temple_ruin`, and the Lurker belongs to the page that spawned it (the ambush event), so the ambush on two pages would share one Lurker.

**Engine (game code, tests, Rules Reference where it changes play):**
- **`AdventureEventScenario`**: groups events and shows at most one, the first whose conditions pass (list order = priority); its own conditions gate the whole group. Extends `AdventurePage` so it fits a host's `events`; its options are its `events`, the page fields it doesn't use are hidden in the Inspector. Pages resolve it through one hook (`AdventurePage.resolve_event(story)`: a page returns itself, a scenario its active option or none), so the Hide flags of the chosen option act on the host as if it were there directly. Lurker: scenario "Lurker" = [Ambush (Hide All, Lurker can fight), Won (adds "Kill the Lurker", Lurker beaten)].
- **`AdventureHostReference`** ("↺ Host"): a page reference meaning the page the event was shown on. `Story._host` = the page on which an event's decision (owner ≠ the page) was last chosen; pages behind the event keep it. References resolve through `AdventurePageReference.resolve(story)`; choices hand Story `get_transition_reference()` (the old `get_transition()` is gone). Fight won and "Kill the Lurker" point to it.
- **Monsters shared or per host**: shared by default (keyed by the spawning event, as before); `AdventurePage.generic` on the spawning event gives each host its own (`Monsters` keyed by [event, host]). On the event, not the fight, so non-combat encounters can use it for what they spawn later.
- Later: a condition "this event hasn't happened yet" for events that may happen in one of several places, but only once.

**Editor:**
- Events tab shows an event on its own: "↺ Host" is a node of its own, no location.
- "At:" picker above the event graph (none or one of its hosts). With a host: "↺ Host" becomes that page, a line says what the event hides there (text, decisions, other events), and whether its monster is per host or shared. A card on the map opens the event with that host picked.
- Clicking a scenario shows all of it: a frame per option (priority order) and per sub-event of the pages inside (Godot frames can't nest, so sub-event frames sit beside, dashed from the page listing them). Everything is editable through the Inspector by selecting it; editing in the graph is v2.

**Order:** [x] scenario → [x] host reference → [x] generic events → [x] Lurker content (`events/lurker.tres` = [Ambush, Won] on Temple Ruin) → [x] editor.

## v2 — editing, slice 1: the map (done 2026-10-27)
The graph edits structure (links, new things, order), the Inspector edits content (text, fields). Tabs stay "Map" and "Events"; no extra panel until one is clearly missing.
- **Link:** drag from a location to another: a plain decision "Go to <title>" with an `AdventureTransition`. **Unlink:** drag a link's end away from its target (`right_disconnects`): removes the page's plain decisions leading there (links made only by fights / saves stay; edited in the events tab later).
- **New location:** right-click on empty space → name + area (an existing one or a new one by name). Locations get their own file, `locations/<area folder>/<name>.tres`; a new area gets `locations/<name>/<name>.tres`. Pages behind events will live inside the event's file (slice 2).
- **Moving a location sets its area:** frames grow with their locations, so a plain drag keeps the area. **Alt+drag** lets a location go of its frame: dropped on empty space it has no area, in another frame that frame's area, back on its own frame it is attached again. A location without an area dropped into a frame joins it. Moving a frame takes its locations along.
- **Placed but unreachable** locations (in the layout, not reached from the start) still show, faded, so new locations don't vanish before they are linked.
- **Undo** through the plugin's `EditorUndoRedoManager`. **Saving:** changes stay unsaved until saved, like editor edits: the plugin reports them (`_get_unsaved_status`) and saves them on Save All, before running and on quit (`_save_external_data`); Ctrl+S in the tab saves too. Creating files (new location / area) is not undone; delete them in the FileSystem.
- [x] Editing helpers (pure, unit tested): link / unlink decisions, new location / area, file paths
- [x] Map view: link, unlink, right-click menu, frame drop
- [x] Root + plugin: undo, unsaved tracking, saving, new-location dialog
- [x] `AdventureGraph` takes placed pages from the layout (unreachable, faded)

## v2 — editing, slice 2: events (built 2026-10-27, manual check open)
- **Links:** drag a decision's or outcome's port onto a page, the host or an exit; dragging a link's end off makes it "(back)". Same file: the page itself; another file: `AdventureTransition`; host: `AdventureHostReference`.
- **New page:** drag a port onto empty space: a page inside the event's file, linked at once.
- **Pages behind an event live inside its file.** A link back to the event or an earlier page of the same file would be a cycle, which one file can't store: refused with a warning (use "(back)", "↺ Host" or a separate file).
- **New decisions:** buttons at the bottom of each page card (and right-click, with icons) → choice / fight / save; fights and saves start empty (enemy, attribute, difficulty in the Inspector).
- **Decisions are cards inside the page card** (2026-10-28, replacing the separate check nodes): a choice with its port; a fight (red, sword) or save (its attribute's color and icon, else blue dice) with a row and port per outcome. Click a card: the decision in the Inspector; ▲ ▼ reorder, ✕ removes.
- **"Host" node in every frame**, linked or not, in its own color with a return icon.
- **No accidental loss:** unlinking, relinking or removing a decision is refused while it is the only way to a page stored in the file; such pages go only by right-click → "Delete page" (everything in the file pointing at it goes back instead).
- **New event / scenario:** right-click a location on the map → a file in the area's `events/` folder, listed on the location.
- Scenario option order: in the Inspector (it reorders arrays already). Putting an existing event on more locations: later, its own step.
- Undo and saving as on the map; edits inside a file mark that file unsaved.
- Inline pages and decisions get their in-file ID (`resource_scene_unique_id`) when created, and the layout keys inline resources by it, so positions survive saving (positions of inline pages placed before reset once).
- [x] Editing helpers (pure, unit tested): references by file, cycle check, new pages / decisions / events, event paths
- [x] Event view: link, unlink, drop on empty, page menu; map: location menu
- [x] Root: undo with the owning file, name dialog, creating event files

- **2026-10-28 additions:** clicking a decision card highlights it; outcome ports and links colored (Won / Success green, Lost / Failure red, Fled yellow, Draw grey); a page without decisions shows the game's automatic "Turn back. (automatic, back 1)"; going back shows its steps ("(back 2)"); effects (consequences) as tags on choices and outcomes (click: Inspector, ✕: remove) with "+ effect" listing every consequence type (`AdventureEventEditing.get_consequence_types`).

## v2 — "Previous location" and special nodes (built 2026-10-28)
"Back" and "↺ Host" are nearly always the same; fleeing should go to the location before the host instead. Leaving is where a decision leads, so a link target rather than an effect:
- New page reference **"↶ Previous location"** (`AdventurePreviousLocationReference`): Story goes back past the host, however deep the event goes (today's `back_steps = 2` only works one page deep). Fled would use it.
- A **sidebar** next to the event graph with special nodes to drag onto a frame: "Host" and "Previous location" (more later, e.g. "End adventure"). Each frame always has its own host; more copies of either can be placed to avoid long links (right-click a placed copy → Remove; its links go to the frame's own again). A frame's own "Previous location" shows when something leads there but no copy is placed. Plain "(back N)" stays.
- Which copy a link goes to: `AdventureLayout.special_links` (link key → node key); placed copies are layout keys `<root>/<entry>/special/<kind>/<n>`.
- Story: `_go(reference, back_steps)` is the one way choices, saves and fights are followed (fights and saves without a transition now also go back their decision's `back_steps`, before always 1). Previous location goes back to the page before the host; nothing before it (the adventure started there): to the host.
- Content: Lurker Ambush Fled's "Continue." leads to "Previous location" instead of `back_steps = 2`.

## v2 — conditions and scenarios (built 2026-10-29, manual check open)
- **Scenario as a switch node** left of its options' frames: its title and own conditions, a row per option in priority order ("1 · Lurker Ambush", its conditions) linked to the option's frame, "otherwise: nothing". ▲ ▼ reorder, ✕ takes an option out (its file stays), "+ option" makes a new event file in the `events/` folder. Frame titles lose the numbers; an option's "When" shows only its own conditions.
- **Conditions as tags** (like effects) on event nodes and the switch node: click → Inspector, ✕ removes, "+ condition" lists every condition type, plus **quick picks** for the monsters of the fights in the overview ("Lurker can fight / is beaten / is dead", `spawned_by` set: none on the fight's own page, a transition to another file, the page in the same file unless that loops).
- **Dotted lines** from a monster condition's tag to the fight card that spawns the monster, in the condition's color.
- A page without decisions: its automatic "Turn back." row has a port; linking it (or dropping it on empty space) adds a real "Continue." choice leading there.
- Idea (user, 2026-10-29), not designed yet: a scenario declares its participants / objects (monsters, characters, items, flags), and conditions are built from them.
- Scaling (user, 2026-10-28): fine for now; more kinds of conditions (characters present, flags set in the game) may need another way to show the choice later.
- [x] Model: switches in the overview, condition types, monster condition quick picks, event paths inside `events/`
- [x] View: condition tags, switch node, dotted lines
- [x] Root: options (add, move, remove)


## v2 — map lines, existing events, nearby events (built 2026-10-29, manual check open)
1. **Map lines:** straight lines between the nearest edges of two locations, one per pair, arrowheads for direction (both for both ways), dashed through events; no GraphEdit curves on the map. Ports stay for dragging new links; unlinking by right-click a location → "Unlink from X".
2. **Existing events:** a sidebar on the map ("Drag onto a location:") lists the adventure's events (known ones and every event file in an `events/` folder under the adventure; `AdventureEventButton`); drag one onto a location to list it there, press one to open it. Also right-click a location → "Add event…" (same list and "Other file…"); right-click an event card on the map → "Remove from here" (the file stays).
3. **Nearby events** (side effects, e.g. Hearing Eleanor belongs to the Eleanor scenario): an event lists `nearby_events`; each shows on the locations around wherever its source is placed, within its `nearby_reach` (1: the locations linked from it; more: further; 0: the whole area, up to `MAX_NEARBY_REACH` links), when its own conditions are met (the source needn't be active). One lookup for game and editor: `AdventurePage.find_nearby_events()` (from the page's own links, `get_linked_locations`, `get_listed_events` incl. scenario options); Story filters and caches per page entered (`Story.get_nearby_events`); they join the page's events after its own, Hide flags as usual. Editor: faded cards on the map ("· from Castle Ruin"), frames "(nearby)" dashed from the source in the event view, right-click an event node → "Add nearby event…" / "Not nearby … any more"; the events list shows them under their source. Content: Hearing Eleanor moves from Rocky Shore into The Mysterious Woman.
- [x] Map lines
- [x] Existing events (add, remove)
- [x] Nearby events: engine + tests, editor, content

## v2 — housekeeping, problems, play from here (built 2026-10-29)
- Cleanup: test content (glhf, asdf, dfgh) removed; the event view split: `AdventureCardView` (decision cards, tags, add bar, selection) between `AdventureGraphView` and `AdventureEventView`.
- **Problems tab** (`AdventureProblems`, unit tested): fights without enemies, saves without attribute, links to missing files (`AdventureTransition.leads_nowhere`), locations not reached from the start, events listed nowhere (pages reached behind events don't count), scenario options after one without conditions, "Host" / "Previous location" outside events. The tab title counts them; clicking one opens the map or the event with its page in the middle (`focus_resource`).
- **Play from here** (right-click a location on the map or a page / event node): saves, writes `AdventurePlayFrom` (adventure, page, host; pages stored inside a file by their file and in-file ID), starts the main scene; a debug run of `Game` takes it once. A location starts as it is; an event's own page starts at its host (the picked one, else the first location it is on); a page behind an event starts on it with the host entered first (`Story.start_adventure(…, page, host)`). Character creation still runs first if the protagonist isn't set up.
- `AdventurePage.get_held_pages()` (game code) is the one walk over what a file holds; the editor's loop and reference checks use it.

## v2 — problems on nodes, drag from FileSystem, search, tidy (built 2026-10-29)
- **Problems on nodes:** a node whose page has a problem gets a warning icon in its title bar, a red title and the problems as tooltip (map and event view).
- **Drag from the FileSystem panel:** an event file onto a location lists it there; an image onto a location, page or area frame makes it the background.
- **Search:** a "Find…" field next to the adventure picker (Ctrl+F in the tab): typing filters the map's event sidebar and the Events list, Enter jumps to the first page or event whose title fits.
- **Tidy:** a button in each graph's toolbar forgets where that graph's nodes were moved (after asking), so they go back to their default places.
- Not wanted (user): a stand-in character for "Play from here"; own text editing in cards (it would want spell checking, rich text, tooltips … — the Inspector stays). Participants stay parked until a second kind exists.
- [x] Problems on nodes
- [x] Drag from FileSystem
- [x] Search
- [x] Tidy

## Cleanup (agreed 2026-10-29, branch `refactor/adventure-editor-cleanup`)
- [x] **A. Decisions know their outcomes:** decision scripts `@tool`; `AdventureDecision.get_outcomes()` ([reference property, name, effects property]) and `get_page_references()`; `Fight`, `StorySaveDecision` and the editor read the same list; no more reading fields by name or walking property lists
- [x] **B + C. Editing in one place:** `AdventureEdits` (undo, unsaved, new files; testable with a plain `UndoRedo`); the views request changes with one signal (`changes_requested`: [resource, property, value] … in a file, as an undo step); `AdventureLayout` builds and recognizes every layout key
- [x] **E. Small things:** event files scanned once per rebuild (also not per Find keystroke); `AdventureTransition` uses `load_page()` in the editor; nearby events follow plain links only (documented)

## Deleting, undoable adding, nearby in the area (2026-10-30)
- **Delete** a location, event or area: right-click → "Delete …", or the Delete key on selected nodes (event view: pages inside a file go as by "Delete page", placed special nodes are removed). After asking, one undo step removes everything pointing at it (`AdventureEventEditing.get_changes_forgetting`: plain decisions leading only there go, fight / save outcomes leading there go back, it is no event, option or nearby event any more; an area is taken off its locations), then its file goes to the system trash. Ctrl+Z restores the links, not the file. The starting page can't be deleted.
- **Adding is undoable:** new locations, areas, events and options are saved as part of their undo step (`AdventureEdits.create`); undo moves the file to the trash, redo saves it again. Moving nodes stays without undo (user: not needed).
- Changes may name the file they are stored in ([resource, property, value, file]).
- **Nearby events can stay in their source's area** (`AdventurePage.nearby_stays_in_area`).

## Later
- Fight decisions (and other checks) with **input ports** for who takes part: link enemies / participants into the fight node instead of picking them in the Inspector (user idea, 2026-10-29; fits the parked participants / cast idea)
- **v2 map editing:** create areas and locations, connect two locations (plain decision "Go to X" + `AdventureTransition`), delete links, move events between hosts by dragging cards, **moving a location into an area frame sets its `area`** (`GraphEdit.graph_elements_linked_to_frame_request`)
- Events tab: edit events (and their inner pages) inside the editor window
- Non-location pages (dialogue, fight outcomes such as the Lurker's won / lost pages)
- Portals: a link into another area ends in a small portal node inside the source frame instead of a long line across the map

## Open
- [x] Manual check (**user**): problem nodes (icon, tooltip), dragging event files and images from the FileSystem panel (location, page, area frame), Find… (typing filters, Enter jumps, Ctrl+F), Tidy in both graphs
- [x] Manual check of map lines (right-click → Unlink from …), "Add event…" / "Other file…" / "Remove from here", "Add nearby event…" (**user**)
- [x] Manual check of conditions and scenarios (**user**): the Lurker's switch node (reorder, + option, ✕), condition tags and "+ condition" with its quick picks, the dotted lines to the fight
- [x] Manual check of event editing (**user**): drag outcome ports onto pages / "↺ Host" / exits, drag a link's end off, drop a port on empty space (new page), right-click a page → Add choice / fight / save, right-click a location on the map → New event / scenario, a loop warning, undo, saving the event file. Only data helpers are unit tested
- [ ] Later (with editable conditions): show how a scenario picks its option better than numbers in the frame titles (user)
- [ ] Map placement still uses a fixed grid (event view stacks by real height now)
- [x] Manual check of checks and page text (**user**): Lurker scenario and The Mysterious Woman, selecting a check node edits the decision
- [x] Manual check of the scenario overview (**user**): click the Lurker scenario, the "At:" picker, frames / nodes → Inspector, "↺ Temple Ruin" double-click, positions per scenario
- [x] Manual check of the events tab (**user**): event list, cards opening events (map and inside events), exit double-click back to the map, positions per event
- [x] Manual check in the editor (**user**): open `test_adventure.tres`, click nodes / cards / frames, move nodes (layout file appears, positions survive a restart), edit a page in the Inspector (graph updates). Only the rendering was checked (screenshots from a game run) and the editor run (3 pages, 2 areas, 4 links), not the clicks
- [ ] Auto placement is a plain grid per area (one row per area), so lines cross until nodes are moved once; judge once there are more locations (user)

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
