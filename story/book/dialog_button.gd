@tool
class_name DialogButton
extends FancyButton

signal save_requested(save_request: SaveRequest, source: StoryDecision)
signal fight_requested(fight_request: FightRequest, source: StoryDecision)

@export var story_decision: StoryDecision:
	set(new_story_decision):
		assert(new_story_decision)
		story_decision = new_story_decision
		if story_decision is StorySaveDecision:
			var story_save_decision: StorySaveDecision = story_decision
			set_icon_colors(story_save_decision.attribute.color)
			set(&"icon", story_save_decision.attribute.icon)
		elif story_decision is StoryFightDecision: glyph = "⚔️"
		set(&"text", story_decision.description)
		name = story_decision.description

@export var shortcuts: Array[Shortcut] = []

var _story: Story
var _characters: Characters

var _selected: bool = false:
	set(new_selected):
		_selected = new_selected
		if _selected: glyph = "✔"
		else: _set_index()

func _ready() -> void:
	_set_index()
	var index: int = get_index()
	if index >= shortcuts.size(): return
	shortcut = shortcuts[index]
	pressed.connect(_on_pressed)

func _exit_tree() -> void:
	if Engine.is_editor_hint(): return
	if _story.decision_made.is_connected(_on_decision_made): _story.decision_made.disconnect(_on_decision_made)

func setup(story: Story, characters: Characters, new_story_decision: StoryDecision) -> void:
	_story = story
	_characters = characters
	story_decision = new_story_decision
	_story.decision_made.connect(_on_decision_made)

func _set_index() -> void:
	glyph = "%d." % [get_index() + 1]

func _on_pressed() -> void:
	if story_decision is StorySaveDecision:
		var save_request: SaveRequest = (story_decision as StorySaveDecision).to_save_request(_characters.get_protagonist())
		save_requested.emit(save_request, story_decision)
	elif story_decision is StoryFightDecision:
		var fight_request: FightRequest = (story_decision as StoryFightDecision).to_fight_request(_characters.get_protagonist())
		fight_requested.emit(fight_request, story_decision)
	else: _story.make_decision(story_decision)

func _on_decision_made(selected_story_decision: StoryDecision, _selected_how_many_times: int) -> void:
	_selected = selected_story_decision == story_decision
	deactivate()
	disabled = not _selected
	release_focus()
	_update_style()
	_story.decision_made.disconnect(_on_decision_made)
