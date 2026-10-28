@tool
class_name AdventureNameDialog
extends ConfirmationDialog

## Asks for a name, then calls back with it

var _name: LineEdit
var _on_named: Callable

func _init() -> void:
	_name = LineEdit.new()
	add_child(_name)
	register_text_enter(_name)
	confirmed.connect(_on_confirmed)

## [param on_named] gets the name
func ask(dialog_title: String, placeholder: String, on_named: Callable) -> void:
	title = dialog_title
	_name.placeholder_text = placeholder
	_name.clear()
	_on_named = on_named
	popup_centered(Vector2i(320, 0))
	_name.grab_focus()

func _on_confirmed() -> void:
	if not _name.text.strip_edges().is_empty(): _on_named.call(_name.text.strip_edges())
