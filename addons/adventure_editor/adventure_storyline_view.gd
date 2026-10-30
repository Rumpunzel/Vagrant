@tool
class_name AdventureStorylineView
extends AdventureGraphView

## An encounter's storyline ([AdventureStoryline]), read-only: a row per stage track with its stages in order, and each event between the stages
## it needs and the stages it sets. Stages named nowhere in the track are marked as problems. Double-click an event to see its pages.

const STAGE_COLOR: Color = Color(0.55, 0.8, 1.0)
const SETS_COLOR: Color = Color(0.6, 1.0, 0.6, 0.9)
const ROW_GAP: float = 120.0

var _key_prefix: String

func show_storyline(encounter: AdventureEncounter) -> void:
	_clear()
	if encounter == null: return
	_key_prefix = "storyline/%s/" % AdventureLayout.get_key(encounter)
	var storyline: AdventureStoryline = AdventureStoryline.new(encounter)
	var top: float = 0.0
	for line: AdventureStoryline.Track in storyline.tracks: top = _add_track(line, top)
	if storyline.unstaged.is_empty(): return
	var label: Label = _make_label("Need and set no stage:\n" + "\n".join(storyline.unstaged.map(AdventureGraph.get_title)))
	_add_node(_key_prefix + "unstaged", encounter, "Other events", label, Vector2(0, top))

## Its stages in a row, its events below them; returns where the next row starts
func _add_track(line: AdventureStoryline.Track, top: float) -> float:
	var stages: Dictionary[String, GraphNode] = {}
	for index: int in line.track.stages.size():
		stages[line.track.stages[index]] = _add_stage(line.track, line.track.stages[index], Vector2(index * 2 * NODE_SPACING.x, top), false)
	var rows: Dictionary[int, int] = {}
	for step: AdventureStoryline.Step in line.steps:
		var column: int = 0
		var first_need: int = line.track.stages.size()
		for need: String in step.needs: first_need = mini(first_need, line.track.stages.find(need))
		if not step.needs.is_empty() and first_need >= 0: column = first_need * 2 + 1
		var row: int = rows.get(column, 0)
		rows[column] = row + 1
		var node: GraphNode = _add_event(line.track, step, Vector2(column * NODE_SPACING.x, top + (row + 1) * NODE_SPACING.y * 0.6))
		for need: String in step.needs: _add_line(_get_stage(stages, line.track, need, top), node, STAGE_COLOR, false, ARROW_END)
		for stage: String in step.sets: _add_line(node, _get_stage(stages, line.track, stage, top), SETS_COLOR, false, ARROW_END)
	var deepest: int = 0
	for column: int in rows: deepest = maxi(deepest, rows[column])
	return top + (deepest + 1) * NODE_SPACING.y * 0.6 + ROW_GAP

## A stage not in the track (a typo in a condition or consequence) gets a node of its own, marked
func _get_stage(stages: Dictionary[String, GraphNode], track: AdventureStageTrack, stage: String, top: float) -> GraphNode:
	if not stages.has(stage): stages[stage] = _add_stage(track, stage, Vector2(stages.size() * 2 * NODE_SPACING.x, top), true)
	return stages[stage]

func _add_stage(track: AdventureStageTrack, stage: String, at: Vector2, unknown: bool) -> GraphNode:
	var label: Label = _make_label("Not a stage of %s" % track.name if unknown else "Stage")
	var node: GraphNode = _add_node(_key_prefix + "%s/%s" % [track.name, stage], track, "%s: %s" % [track.name, stage], label, at)
	node.self_modulate = PROBLEM_COLOR if unknown else STAGE_COLOR
	return node

func _add_event(track: AdventureStageTrack, step: AdventureStoryline.Step, at: Vector2) -> GraphNode:
	var lines: Array[String] = [ ]
	lines.append("Needs %s" % " or ".join(step.needs) if not step.needs.is_empty() else "Needs no stage")
	if not step.sets.is_empty(): lines.append("Sets %s" % ", ".join(step.sets))
	var title: String = AdventureGraph.get_title(step.event) + (" (near)" if step.event.where == AdventureEvent.Where.NEAR else "")
	var node: GraphNode = _add_node(_key_prefix + "%s/event/%s" % [track.name, AdventureLayout.get_key(step.event)], step.event, title, _make_label("\n".join(lines)), at)
	node.gui_input.connect(func(input: InputEvent) -> void:
		var click: InputEventMouseButton = input as InputEventMouseButton
		if click != null and click.double_click: call_after_release(event_opened.emit.bind(step.event, null))
	)
	return node

func _on_event_card_pressed(event: AdventureEvent, _page: AdventurePage) -> void: event_opened.emit(event, null)
