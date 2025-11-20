@tool
class_name AttributeScoreRoller
extends PanelContainer

signal attribute_score_rolled(attribute: CharacterAttribute, attribute_score: RolledAttributeScore)

@export var attribute: CharacterAttribute :
	set(new_attribute):
		assert(new_attribute)
		attribute = new_attribute
		if not is_node_ready(): await ready
		_attribute_score.attribute = attribute
		_descriptor.text = attribute.descriptor
		_details.text = attribute.details
		tooltip_text = attribute.details

@export_group("Configuration")
@export var _attribute_score: CharacterSheetAttributeScore
@export var _button: DisplayButton
@export var _descriptor: Label
@export var _details: RichTextLabel
@export var _score: RichTextLabel

var score: RolledAttributeScore :
	set(new_score):
		score = new_score
		_button.disabled = true  
		update()

var modifiers: Array[AttributeScore.Modifier] = [] :
	set(new_modifiers):
		modifiers = new_modifiers
		update()

func _ready() -> void:
	if not get_viewport().gui_get_focus_owner(): _button.grab_focus()

func update() -> void:
	var attribute_score: AttributeScore = _get_attribute_score()
	_attribute_score.score = attribute_score
	_score.text = "%s = %d" % [attribute_score.get_details(), attribute_score.get_score()]

func disable() -> void:
	_button.disabled = true
	_button.active = false
	var next: Control = find_valid_focus_neighbor(SIDE_RIGHT)
	if not next: next = find_valid_focus_neighbor(SIDE_LEFT)
	if next: next.grab_focus()

func _get_attribute_score() -> AttributeScore:
	return AttributeScore.new(attribute, score, modifiers)

func _on_button_pressed() -> void:
	disable()
	score = DiceRoller.roll_attribute()
	attribute_score_rolled.emit(attribute, score)
