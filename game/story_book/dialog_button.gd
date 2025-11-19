@tool
class_name DialogButton
extends FancyButton

@export var state: StoryEntry.State = StoryEntry.State.PRESENT:
	set(new_state):
		state = new_state
		match state:
			StoryEntry.State.PRESENT:
				activate()
				disabled = false
				if _story_choice: _story_choice.discard()
				_set_index()
			StoryEntry.State.PAST:
				deactivate()
				disabled = not _story_choice.is_chosen()
				if _story_choice.is_chosen(): set(&"icon", _chosen_icon)
				else: _story_choice.discard()
				release_focus()
				_update_style()
			_: assert(false, "Does not exist")

@export var _chosen_icon: Texture2D

@export_group("Configuration")
@export var shortcuts: Array[Shortcut] = []

var _story_choice: StoryChoice:
	set(new_story_choice):
		assert(new_story_choice)
		if _story_choice is StoryDiceDecision:
			(_story_choice as StoryDiceDecision).icon_changed.disconnect(_update_icon)
		_story_choice = new_story_choice
		var description: String = _story_choice.get_description()
		set(&"text", description)
		name = description
		_update_icon()
		if _story_choice is StoryDiceDecision:
			(_story_choice as StoryDiceDecision).icon_changed.connect(_update_icon)

func _ready() -> void:
	_set_index()
	var index: int = get_index()
	if index >= shortcuts.size(): return
	shortcut = shortcuts[index]

func setup(story_choice: StoryChoice, dialog_button_group: ButtonGroup) -> void:
	_story_choice = story_choice
	button_group = dialog_button_group

func _update_icon() -> void:
	set(&"icon", _story_choice.get_icon())
	set_icon_colors(_story_choice.get_icon_color())

func _set_index() -> void:
	glyph = "%d." % [get_index() + 1]

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		assert(not _story_choice.is_chosen())
		grab_focus()
		_story_choice.chose()
	else: _story_choice.discard()
