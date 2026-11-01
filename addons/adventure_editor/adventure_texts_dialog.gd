@tool
class_name AdventureTextsDialog
extends ConfirmationDialog

## Asks for a few texts at once, each filled in with what it is now, then calls back with them

## One text to ask for
class Field:
	var label: String
	var value: String
	var placeholder: String
	## A box for several lines instead of one line
	var multiline: bool

	func _init(field_label: String, field_value: String, field_placeholder: String = "", is_multiline: bool = false) -> void:
		label = field_label
		value = field_value
		placeholder = field_placeholder
		multiline = is_multiline

var _fields: VBoxContainer
var _on_confirmed: Callable

func _init() -> void:
	_fields = VBoxContainer.new()
	add_child(_fields)
	confirmed.connect(func() -> void: _on_confirmed.call(_get_texts()))

## [param on_confirmed] gets the texts (stripped), in the order of [param fields]
func ask(dialog_title: String, fields: Array[Field], on_confirmed: Callable) -> void:
	title = dialog_title
	_on_confirmed = on_confirmed
	for child: Node in _fields.get_children():
		_fields.remove_child(child)
		child.queue_free()
	for field: Field in fields:
		var label: Label = Label.new()
		label.text = field.label
		_fields.add_child(label)
		_fields.add_child(_make_input(field))
	popup_centered(Vector2i(420, 0))
	(_fields.get_child(1) as Control).grab_focus()

func _make_input(field: Field) -> Control:
	if field.multiline:
		var box: TextEdit = TextEdit.new()
		box.text = field.value
		box.placeholder_text = field.placeholder
		box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		box.custom_minimum_size.y = 80
		return box
	var line: LineEdit = LineEdit.new()
	line.text = field.value
	line.placeholder_text = field.placeholder
	register_text_enter(line)
	return line

func _get_texts() -> Array[String]:
	var texts: Array[String] = [ ]
	for child: Node in _fields.get_children():
		if child is LineEdit: texts.append((child as LineEdit).text.strip_edges())
		elif child is TextEdit: texts.append((child as TextEdit).text.strip_edges())
	return texts
