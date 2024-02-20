class_name StoryDecision
extends Resource

@export var description := ""
@export var next_story_page: StoryPage = null
@export var attribute: CharacterAttribute = null
@export_range(0, 12) var difficulty := 0
@export_multiline var details := ""
@export var failure_story_page: StoryPage = null

func to_save_request() -> SaveRequest:
	var protagonist: Character = Characters.get_protagonist()
	return SaveRequest.new(protagonist, attribute, difficulty, details)

func to_dialog_button_text() -> String:
	var result := ""
	if attribute != null: result += "[color=#%s][%s][/color] " % [attribute.color.to_html(), attribute]
	result += description
	return result
