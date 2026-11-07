@tool
class_name AdventureActionMenu
extends PopupMenu

## A context menu at the mouse: item text -> what it does (an empty Callable: shown, but disabled); each item gets an editor icon by the words in
## its text. "Gain › Sword" goes into a submenu "Gain".

const ICON_SIZE: int = 16
const SUBMENU: String = " › "
## [words, icon name]: the first entry with a word in an item's text gives its icon
const ICONS: Array[Array] = [
	[["starting page"], "Favorites"], [["texts", "rename"], "Edit"], [["inspector"], "Object"], [["can't"], "NodeWarning"], [["play"], "Play"],
	[["unlink"], "Unlinked"], [["remove", "delete", "not nearby", "not here"], "Remove"], [["other file"], "Load"], [["(scenario)"], "GraphEdit"],
	[["monster"], "Skeleton2D"], [["encounter", "place "], "CharacterBody2D"], [["new ", "add "], "Add"],
]

var _actions: Dictionary[String, Callable] = {}

func _init() -> void:
	index_pressed.connect(_on_pressed.bind(self, ""))

## [param pick_icon]: text -> icon, for menus with icons of their own (a submenu's own entry gets its name's)
func show_actions(actions: Dictionary[String, Callable], pick_icon: Callable = AdventureActionMenu.get_icon) -> void:
	_actions = actions
	clear()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var submenus: Dictionary[String, PopupMenu] = {}
	for text: String in actions:
		if not text.contains(SUBMENU):
			_add_action(self, text, actions[text], pick_icon.call(text))
			continue
		var group: String = text.get_slice(SUBMENU, 0)
		if not submenus.has(group):
			var submenu: PopupMenu = PopupMenu.new()
			submenu.index_pressed.connect(_on_pressed.bind(submenu, group + SUBMENU))
			add_child(submenu)
			add_submenu_node_item(group, submenu)
			_set_icon(self, pick_icon.call(group))
			submenus[group] = submenu
		_add_action(submenus[group], text.substr(group.length() + SUBMENU.length()), actions[text], pick_icon.call(text))
	position = DisplayServer.mouse_get_position()
	reset_size()
	popup()

func _add_action(menu: PopupMenu, label: String, action: Callable, icon: Texture2D) -> void:
	menu.add_item(label)
	_set_icon(menu, icon)
	menu.set_item_disabled(menu.item_count - 1, not action.is_valid())

func _set_icon(menu: PopupMenu, icon: Texture2D) -> void:
	if icon == null: return
	menu.set_item_icon(menu.item_count - 1, icon)
	menu.set_item_icon_max_width(menu.item_count - 1, ICON_SIZE)

## [param prefix]: a submenu's "Gain › "
func _on_pressed(index: int, menu: PopupMenu, prefix: String) -> void:
	var text: String = prefix + menu.get_item_text(index)
	if _actions.has(text) and _actions[text].is_valid(): _actions[text].call()

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
