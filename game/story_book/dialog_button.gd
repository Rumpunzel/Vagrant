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
				if story_choice: story_choice.discard()
				_set_index()
			StoryEntry.State.PAST:
				deactivate()
				disabled = not story_choice.is_chosen()
				if story_choice.is_chosen(): glyph = "✔"
				else: story_choice.discard()
				release_focus()
				_update_style()
			_: assert(false, "Does not exist")

@export_group("Configuration")
@export var shortcuts: Array[Shortcut] = []

var story_choice: StoryChoice:
	set(new_story_choice):
		assert(new_story_choice)
		story_choice = new_story_choice
		var description: String = story_choice.get_description()
		set(&"text", description)
		name = description
		set(&"icon", story_choice.get_icon())
		set_icon_colors(story_choice.get_icon_color())

func _ready() -> void:
	_set_index()
	var index: int = get_index()
	if index >= shortcuts.size(): return
	shortcut = shortcuts[index]

func _set_index() -> void:
	glyph = "%d." % [get_index() + 1]

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		assert(not story_choice.is_chosen())
		story_choice.chose()
	else:
		assert(story_choice.is_chosen())
		story_choice.discard()
