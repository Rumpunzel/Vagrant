class_name StoryDecision
extends Resource

@export var description := ""
@export var next_story_page: StoryPage = null
@export var attribute: CharacterAttribute = null
@export_range(0, 12) var difficulty := 0
@export_multiline var details := ""
@export var failure_story_page: StoryPage = null

func to_save_request() -> SaveRequest:
	return SaveRequest.new(Protagonist, attribute, difficulty, details)

func _to_string() -> String:
	var result := ""
	if attribute != null: result += "[%s] " % attribute
	result += description
	return result
