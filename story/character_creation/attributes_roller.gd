@tool
class_name AttributesRoller
extends HBoxContainer

@export var _continue: Button
@export var _attribute_score_roller: PackedScene

var _attribute_score_rollers: Dictionary[CharacterAttribute, AttributeScoreRoller] = { }

func _ready() -> void:
	_setup()

func _setup() -> void:
	assert(_attribute_score_rollers.is_empty())
	for index: int in Rules.ATTRIBUTES.size():
		var attribute: CharacterAttribute = Rules.ATTRIBUTES[index]
		var attribute_score_roller: AttributeScoreRoller = _attribute_score_roller.instantiate()
		attribute_score_roller.attribute = attribute as CharacterAttribute
		_attribute_score_rollers[attribute] = attribute_score_roller
		add_child(attribute_score_roller)
		if index == Rules.ATTRIBUTES.size() - 1:
			attribute_score_roller._roll.pressed.connect(_continue.grab_focus)
			attribute_score_roller._roll.pressed.connect(_continue.set_disabled.bind(false))
		if index == 0: continue
		var previous_attribute_score_roller: AttributeScoreRoller = _attribute_score_rollers[Rules.ATTRIBUTES[index - 1]]
		previous_attribute_score_roller._roll.pressed.connect(attribute_score_roller._roll.grab_focus)
