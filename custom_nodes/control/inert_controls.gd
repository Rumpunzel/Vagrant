class_name InertControls
extends RefCounted

## Makes controls inert (a past page of the story book): they still show what they show and respond to the mouse being over them, with
## their tooltips, but take no clicks, focus or keys. The mouse wheel still reaches what scrolls them.

static func make_inert(node: Node) -> void:
	if node is DisplayButton: (node as DisplayButton).active = false
	if node is BaseButton:
		var button: BaseButton = node
		button.button_mask = 0
		button.shortcut = null
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	elif node is LineEdit: (node as LineEdit).editable = false
	elif node is TextEdit: (node as TextEdit).editable = false
	# Not every Range: scroll bars stay usable
	elif node is Slider: (node as Slider).editable = false
	elif node is SpinBox: (node as SpinBox).editable = false
	if node is Control: (node as Control).focus_mode = Control.FOCUS_NONE
	# Also internal children (a label's scroll bars, a button's own labels)
	for child: Node in node.get_children(true): make_inert(child)
