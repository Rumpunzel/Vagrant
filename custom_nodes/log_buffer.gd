class_name LogBuffer
extends Logger

## Keeps what is logged (prints, warnings, errors) until [method take] collects it. Godot calls it from any thread, so it locks; it must
## not print itself (that would log again).

enum Kind { MESSAGE, WARNING, ERROR }

## Kept while nobody collects
const LIMIT: int = 2000

var _mutex: Mutex = Mutex.new()
var _lines: Array[Dictionary] = []

func _log_message(message: String, error: bool) -> void:
	_add(message.strip_edges(false, true), Kind.ERROR if error else Kind.MESSAGE)

func _log_error(
	function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]
) -> void:
	var warning: bool = error_type == ERROR_TYPE_WARNING
	var text: String = "%s: %s (%s:%d, %s)" % ["WARNING" if warning else "ERROR", rationale if not rationale.is_empty() else code, file, line, function]
	_add(text, Kind.WARNING if warning else Kind.ERROR)

## The lines logged since the last call: { text, kind }
func take() -> Array[Dictionary]:
	_mutex.lock()
	var taken: Array[Dictionary] = _lines
	_lines = []
	_mutex.unlock()
	return taken

func _add(text: String, kind: Kind) -> void:
	_mutex.lock()
	_lines.append({text = text, kind = kind})
	if _lines.size() > LIMIT: _lines = _lines.slice(-LIMIT)
	_mutex.unlock()
