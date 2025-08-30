@tool
class_name AttributesRoller
extends VBoxContainer

signal attributes_rolled(attribute_scores: Dictionary[CharacterAttribute, AttributeScore])

@export_group("Configuration")
@export var _roller_container: Container
@export var _attribute_score_roller: PackedScene

var _attribute_scores: Dictionary[CharacterAttribute, BaseAttributeScore] = { }

func _ready() -> void:
	if not Engine.is_editor_hint(): return
	setup()

func setup() -> void:
	for attribute_score_roller: AttributeScoreRoller in _roller_container.get_children():
		_roller_container.remove_child(attribute_score_roller)
		attribute_score_roller.queue_free()
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var attribute_score_roller: AttributeScoreRoller = _attribute_score_roller.instantiate()
		attribute_score_roller.attribute = attribute
		attribute_score_roller.attribute_score_rolled.connect(_on_attribute_score_rolled)
		_roller_container.add_child(attribute_score_roller)

func update_modifiers(modifers: Array[AttributeScore.Modifier]) -> void:
	for attribute_score_roller: AttributeScoreRoller in _roller_container.get_children():
		attribute_score_roller.modifiers = modifers

func collapse() -> void:
	size_flags_vertical = Control.SIZE_FILL
	for attribute_score_roller: AttributeScoreRoller in _roller_container.get_children():
		attribute_score_roller.collapse()

func _is_ready() -> bool:
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: if not _attribute_scores.has(attribute): return false
	return true

func _on_attribute_score_rolled(attribute: CharacterAttribute, attribute_score: BaseAttributeScore) -> void:
	_attribute_scores[attribute] = attribute_score
	if _is_ready(): attributes_rolled.emit(_attribute_scores)
