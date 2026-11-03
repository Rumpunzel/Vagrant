class_name MetaTooltipTrigger
extends TooltipTrigger

## A tooltip for each link ([code][url][/code]) of a [RichTextLabel] ([member trigger_node]) rather than for the whole label: shown while
## a link is hovered, with what [member tooltip_for] gives for its meta (nothing: no tooltip).

## (meta: Variant) -> Array[String], the tooltip's strings ([member TooltipTrigger.tooltip_strings])
var tooltip_for: Callable

func init_signals() -> void:
	var label: RichTextLabel = trigger_node as RichTextLabel
	assert(label != null, "A MetaTooltipTrigger's trigger_node is a RichTextLabel")
	control_node = label
	label.meta_hover_started.connect(_on_meta_hover_started)
	label.meta_hover_ended.connect(_on_meta_hover_ended)

func _on_meta_hover_started(meta: Variant) -> void:
	if not tooltip_for.is_valid(): return
	var strings: Array[String] = tooltip_for.call(meta)
	if strings.is_empty(): return
	tooltip_strings = strings
	_on_mouse_entered()

func _on_meta_hover_ended(_meta: Variant) -> void: _on_mouse_exited()
