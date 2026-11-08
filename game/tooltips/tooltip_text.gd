class_name TooltipText
extends RefCounted

## The game's tooltips: what matters first, then what explains it in dimmer italics, wrapping at the width the game's tooltip template
## wraps at too ([member Tooltip.max_width]).

const MAX_WIDTH: float = 280.0
const DETAIL_COLOR: Color = Color(1.0, 1.0, 1.0, 0.6)

static func compose(main: String, detail: String) -> String:
	return "%s\n[i][color=#%s]%s[/color][/i]" % [main, DETAIL_COLOR.to_html(), detail]

## For [method Control._make_custom_tooltip] of [param host]: Godot's own tooltips show text plainly and never wrap
static func make_label(bbcode: String, host: Control) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = bbcode
	Tooltip.fit_width(label, MAX_WIDTH)
	# Godot keeps its tooltips on screen by the size they have as they open, before a wrapping label is laid out (it would count one
	# line): laid out once at its width in the host, with the host's theme, it knows its real height
	host.add_child(label, false, Node.INTERNAL_MODE_BACK)
	label.size.x = label.custom_minimum_size.x if label.autowrap_mode != TextServer.AUTOWRAP_OFF else float(label.get_content_width())
	label.custom_minimum_size.y = label.get_content_height()
	host.remove_child(label)
	return label
