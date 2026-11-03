@tool
class_name GameDebuggerCapture
extends EditorDebuggerPlugin

## Opens what the game asks for ([constant GameDebuggerLinks.OPEN]): a script at a line ("res://a.gd:12", also "res://a.gd:12:function"),
## or a resource by [ResourceId]

func _has_capture(prefix: String) -> bool: return prefix == GameDebuggerLinks.PREFIX

func _capture(message: String, data: Array, _session_id: int) -> bool:
	if message != GameDebuggerLinks.OPEN or data.is_empty(): return false
	open(data[0] as String)
	return true

static func open(target: String) -> void:
	var at_line: RegExMatch = RegEx.create_from_string("^(.+?\\.\\w+):(\\d+)").search(target)
	var id: String = at_line.get_string(1) if at_line != null else target
	var resource: Resource = ResourceId.find(id)
	if resource == null:
		push_warning("The game asked to open %s, which doesn't exist." % target)
		return
	if resource is Script: EditorInterface.edit_script(resource as Script, int(at_line.get_string(2)) if at_line != null else -1)
	else: EditorInterface.edit_resource(resource)
	var editor_window: Window = EditorInterface.get_base_control().get_window()
	editor_window.grab_focus()
	editor_window.request_attention()
