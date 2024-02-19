class_name StoryEntry
extends VBoxContainer

signal hit_dice_selection_added(hit_dice_selection: HitDiceSelection)

@export_group("Configuration")
@export var _description: RichTextLabel
@export var _choices: Container
@export var _hit_dice_selection: PackedScene

var _save_request: SaveRequest
var _save_result: SaveResult

func _progress_story() -> void:
	print("SUCCESS!")

func _handle_failure() -> void:
	print("FAILURE!")

func _on_save_requested(save_request: SaveRequest) -> void:
	_save_request = save_request
	var hit_dice_selection: HitDiceSelection = _hit_dice_selection.instantiate()
	hit_dice_selection.request_save(_save_request)
	hit_dice_selection.save_evaluated.connect(_on_save_evaluated)
	add_child(hit_dice_selection)
	await get_tree().process_frame
	hit_dice_selection_added.emit(hit_dice_selection)

func _on_save_evaluated(save_result: SaveResult) -> void:
	_save_result = save_result
	if _save_result.save_outcome != SaveResult.Outcome.FAILURE:
		_progress_story()
	else:
		_handle_failure()
