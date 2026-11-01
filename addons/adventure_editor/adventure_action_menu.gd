@tool
class_name AdventureActionMenu
extends PopupMenu

## A context menu at the mouse: item text -> what it does; each item gets an editor icon by the words in its text

const ICON_SIZE: int = 16
## [words, icon name]: the first entry with a word in an item's text gives its icon
const ICONS: Array[Array] = [
	[["starting page"], "Favorites"], [["texts"], "Edit"], [["play"], "Play"], [["unlink"], "Unlinked"], [["remove", "delete", "not nearby", "not here"], "Remove"], [["other file"], "Load"],
	[["(scenario)"], "GraphEdit"], [["monster"], "Skeleton2D"], [["encounter", "place "], "CharacterBody2D"], [["new ", "add "], "Add"],
]

var _actions: Dictionary[String, Callable] = {}

func _init() -> void:
	index_pressed.connect(func(index: int) -> void: _actions[get_item_text(index)].call())

## [param pick_icon]: text -> icon, for menus with icons of their own
func show_actions(actions: Dictionary[String, Callable], pick_icon: Callable = AdventureActionMenu.get_icon) -> void:
	_actions = actions
	clear()
	for text: String in actions:
		var icon: Texture2D = pick_icon.call(text)
		if icon != null: add_icon_item(icon, text)
		else: add_item(text)
		set_item_icon_max_width(item_count - 1, ICON_SIZE)
	position = DisplayServer.mouse_get_position()
	reset_size()
	popup()

## The icon of a menu item, by the words in it
static func get_icon(text: String) -> Texture2D:
	var lower: String = text.to_lower()
	for words: Array in ICONS:
		for word: String in words[0]: if lower.contains(word): return get_editor_icon(words[1])
	return get_editor_icon("Object")

## An event's kind: an encounter (a monster's or someone's), a scenario, a plain event
static func get_event_icon(event: AdventureEvent) -> Texture2D:
	if event is AdventureEncounter: return get_editor_icon("Skeleton2D" if (event as AdventureEncounter).profile is MonsterProfile else "CharacterBody2D")
	return get_editor_icon("GraphEdit" if event is AdventureEventScenario else "Signal")

## None where there is no editor (previews)
static func get_editor_icon(icon_name: String) -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(icon_name, &"EditorIcons") if Engine.is_editor_hint() else null
