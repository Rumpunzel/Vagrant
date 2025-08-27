@tool
extends Node

@export var _backgrounds: Array[Texture2D]

@export_group("Configuration")
@export var _stage: Stage
@export var _attributes_roller: AttributesRoller
@export var _origins_picker: OriginsPicker
@export var _bio_editor: BioEditor

var _attribute_scores: Dictionary[CharacterAttribute, AttributeScore]
var _kin: Origin
var _ilk: Origin

func _ready() -> void:
	_origins_picker.visible = false
	_attributes_roller.setup()

func _on_attributes_rolled(attribute_scores: Dictionary[CharacterAttribute, AttributeScore]) -> void:
	_attribute_scores = attribute_scores
	_attributes_roller.collapse()
	var doubles_rolled: int = 0
	for attribute_score: AttributeScore in _attribute_scores.values():
		if attribute_score.get_type() == AttributeScore.Type.DOUBLE: doubles_rolled += 1
	_origins_picker.setup(doubles_rolled)
	# TODO: animate this
	_bio_editor.show()

func _on_origins_picked(kin: Origin, ilk: Origin) -> void:
	_kin = kin
	_ilk = ilk
	_origins_picker.collapse()

func _on_background_timer_timeout() -> void:
	if _backgrounds.is_empty(): return
	_stage.background = _backgrounds.pick_random()
