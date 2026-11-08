@tool
class_name AbilityLabel
extends PanelContainer

@export var origin: Origin :
	set(new_origin):
		origin = new_origin
		_name.visible = origin != null
		_clear()
		if not origin:
			_name.text = "Origin"
			_icon.texture = null
			return
		_name.text = origin.name
		for ability: Ability in origin.abilities:
			_add(ability.description)
		_icon.texture = origin.icon

@export_group("Configuration")
@export var _icon: TextureRect
@export var _name: Label
@export var _abilities: Container

func _clear() -> void:
	for child: Node in _abilities.get_children():
		_abilities.remove_child(child)
		child.queue_free()

func _add(ability: String) -> void:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.text = RulesGlossary.link(ability)
	var tooltips: MetaTooltipTrigger = MetaTooltipTrigger.new()
	tooltips.trigger_node = label
	tooltips.origin = TooltipEnums.TooltipOrigin.MOUSE_POSITION_START
	tooltips.offset = Vector2(16.0, 16.0)
	tooltips.overflow_mode = TooltipEnums.OverflowMode.CLAMP
	tooltips.tooltip_for = RulesGlossary.tooltip_for
	label.add_child(tooltips)
	_abilities.add_child(label)
