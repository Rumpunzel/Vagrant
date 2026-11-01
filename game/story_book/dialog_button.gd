@tool
class_name DialogButton
extends FancyButton

@export var state: StoryEntry.State = StoryEntry.State.PRESENT:
	set(new_state):
		state = new_state
		match state:
			StoryEntry.State.PRESENT:
				activate()
				_update_availability()
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
		if _story_choice:
			_story_choice.icon_changed.disconnect(_update_icon)
			_story_choice.availability_changed.disconnect(_update_availability)
		_story_choice = new_story_choice
		var description: String = _story_choice.get_description()
		set(&"text", description)
		name = description
		_update_icon()
		_story_choice.icon_changed.connect(_update_icon)
		_update_availability()
		_story_choice.availability_changed.connect(_update_availability)

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

## Only while it is the present choice; a past page's buttons go by what was chosen
func _update_availability() -> void:
	if state != StoryEntry.State.PRESENT: return
	var reason: String = _story_choice.get_unavailable_reason() if _story_choice else ""
	set(&"disabled", not reason.is_empty())
	tooltip_text = reason

func _set_index() -> void:
	glyph = "%d." % [get_index() + 1]

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		assert(not _story_choice.is_chosen())
		grab_focus()
		_story_choice.chose()
	else: _story_choice.discard()
