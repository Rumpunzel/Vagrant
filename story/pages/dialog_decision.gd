extends Button

@export var story_decision: StoryDecision :
	set(new_story_decision):
		story_decision = new_story_decision
		text = "%s" % story_decision

var _save_request: HitDiceSelection.SaveRequest

func _enter_tree() -> void:
	Events.save_evaluated.connect(_on_save_evaluated)
	pressed.connect(_on_pressed)

func _exit_tree() -> void:
	Events.save_evaluated.connect(_on_save_evaluated)

func _progress_story() -> void:
	print("SUCCESS!")

func _handle_failure() -> void:
	print("FAILURE!")

func _request_save() -> void:
	_save_request = story_decision.to_save_request()
	Events.save_requested.emit(_save_request)

func _on_pressed() -> void:
	if story_decision.attribute != null:
		_request_save()
	else:
		_progress_story()

func _on_save_evaluated(save_result: SaveResult, save_request: HitDiceSelection.SaveRequest) -> void:
	if save_request != _save_request: return
	if save_result.save_outcome != SaveResult.Outcome.FAILURE:
		_progress_story()
	else:
		_handle_failure()
