@tool
extends EditorPlugin

## Listens to the running game's debug panel ([GameDebuggerLinks]) over the debugger connection

var _capture: GameDebuggerCapture = GameDebuggerCapture.new()

func _enter_tree() -> void: add_debugger_plugin(_capture)
func _exit_tree() -> void: remove_debugger_plugin(_capture)
