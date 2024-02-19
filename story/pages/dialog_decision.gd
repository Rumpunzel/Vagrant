extends Button

signal story_continued
signal save_requested(save_request: SaveRequest)

@export var story_decision: StoryDecision :
	set(new_story_decision):
		story_decision = new_story_decision
		text = "%s" % story_decision

func _enter_tree() -> void:
	pressed.connect(_on_pressed)

func _exit_tree() -> void:
	pressed.disconnect(_on_pressed)

func _on_pressed() -> void:
	if story_decision.attribute != null:
		var save_request := story_decision.to_save_request()
		save_requested.emit(save_request)
	else:
		story_continued.emit()
