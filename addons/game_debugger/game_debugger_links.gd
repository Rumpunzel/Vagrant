class_name GameDebuggerLinks
extends RefCounted

## The game's side: asks the editor it runs from to open a file ([GameDebuggerCapture]); does nothing without one (exported game).

const PREFIX: String = "vagrant"
const OPEN: String = PREFIX + ":open"

## Script paths and [ResourceId]s, optionally with ":line"
const PATTERN: String = "(?:res|uid|user)://[^\\s,()\\[\\]\"]+"

static func can_open() -> bool: return EngineDebugger.is_active()

## [param target]: [code]res://a.gd:12[/code], or a [ResourceId]
static func open(target: String) -> void:
	if can_open(): EngineDebugger.send_message(OPEN, [target])
