@tool
class_name RichTooltipTrigger
extends MetaTooltipTrigger

## Rich tooltips in the editor's tooltip look ([RichTooltip]) for editor tools: about its control while it is hovered ([member content]), or
## (no content) one for each link of a [RichTextLabel]. Once a tooltip locks, its own links get tooltips too ([member describe_link]) and can be
## clicked ([member open_link]). Made by whoever describes the tooltips (not by a static function here: a class making itself crashed Godot on
## quitting).

const TEMPLATE: String = "uid://bqx71b5tyglth"  # rich_tooltip.tscn

## () -> String: the tooltip of the whole control, read each time it opens; not valid: a tooltip per link of the label
var content: Callable
## (meta: Variant) -> String: what a link shows, in this label or in the tooltips ("": nothing)
var describe_link: Callable
## (meta: Variant) -> void: a link was clicked; not valid: links can't be clicked
var open_link: Callable
## Kept alive while the trigger is: what the callables above belong to (a Callable doesn't keep its object alive)
var describer: RefCounted

func _init() -> void:
	super()
	tooltip_template_path = TEMPLATE
	origin = TooltipEnums.TooltipOrigin.MOUSE_POSITION_START
	offset = Vector2(16.0, 16.0)
	overflow_mode = TooltipEnums.OverflowMode.CLAMP
	tooltip_settings_override = _make_settings()
	tooltip_for = _describe_link

## Opens a little later than the editor's own tooltips and locks soon, so its links can be reached
static func _make_settings() -> TooltipSettings:
	var settings: TooltipSettings = TooltipSettings.new()
	settings.open_delay = 0.4
	settings.timer_lock_delay = 0.6
	settings.unlock_delay = 0.3
	return settings

func init_signals() -> void:
	if not content.is_valid():
		super()
		return
	control_node = trigger_node as Control
	control_node.mouse_entered.connect(_on_content_hovered)
	control_node.mouse_exited.connect(_on_mouse_exited)

## The content changed while hovered (e.g. another bar of a chart): shows the new one, or nothing if it is empty
func refresh() -> void:
	cancel_open_delay()
	if active_tooltip: TooltipManager.remove_tooltip(active_tooltip, false)
	state = TooltipEnums.TriggerState.READY
	_on_content_hovered()

func _on_content_hovered() -> void:
	var text: String = content.call()
	if text.is_empty(): return
	tooltip_strings = [text] as Array[String]
	_on_mouse_entered()

func _describe_link(meta: Variant) -> Array[String]:
	if not describe_link.is_valid(): return [] as Array[String]
	var text: String = describe_link.call(meta)
	if text.is_empty(): return [] as Array[String]
	return [text] as Array[String]
