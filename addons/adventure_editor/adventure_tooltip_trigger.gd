@tool
class_name AdventureTooltipTrigger
extends MetaTooltipTrigger

## The adventure editor's rich tooltips ([AdventureTooltip]): about [member subject] while its control is hovered, or (no subject) about each
## link of a [RichTextLabel], which is how the links in a tooltip get theirs. Made by [method AdventureTooltips.attach] (not by a static
## function here: a class making itself crashed Godot on quitting).

const TEMPLATE: String = "uid://c1kgx2o281l1w"  # adventure_tooltip.tscn
const SETTINGS_SCRIPT: Script = preload("uid://lcf8uedn57am")  # tooltip_settings.gd

## What the tooltips say
var tooltips: AdventureTooltips
## None: a tooltip per link of the label
var subject: Resource
## What clicking the control does, said last
var click: String

func _init() -> void:
	super()
	tooltip_template_path = TEMPLATE
	origin = TooltipEnums.TooltipOrigin.MOUSE_POSITION_START
	offset = Vector2(16.0, 16.0)
	overflow_mode = TooltipEnums.OverflowMode.CLAMP
	tooltip_settings_override = _make_settings()
	tooltip_for = _describe_link

## Opens a little later than the editor's own tooltips and locks soon, so its links can be reached
static func _make_settings() -> Resource:
	var settings: Resource = SETTINGS_SCRIPT.new()
	settings.set(&"open_delay", 0.4)
	settings.set(&"timer_lock_delay", 0.6)
	settings.set(&"unlock_delay", 0.3)
	return settings

func init_signals() -> void:
	if subject == null:
		super()
		return
	control_node = trigger_node as Control
	control_node.mouse_entered.connect(_on_subject_hovered)
	control_node.mouse_exited.connect(_on_mouse_exited)

func _on_subject_hovered() -> void:
	tooltip_strings = [tooltips.describe_with_click(subject, click)] as Array[String]
	_on_mouse_entered()

func _describe_link(meta: Variant) -> Array[String]:
	var text: String = tooltips.describe_link(meta)
	if text.is_empty(): return [] as Array[String]
	return [text] as Array[String]
