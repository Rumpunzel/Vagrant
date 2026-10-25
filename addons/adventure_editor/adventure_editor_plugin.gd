@tool
extends EditorPlugin

const AdventureEditorScene: PackedScene = preload("uid://btrr51xe6kwox")  # adventure_editor.tscn

var _editor: AdventureEditor

func _enter_tree() -> void:
	_editor = AdventureEditorScene.instantiate()
	EditorInterface.get_editor_main_screen().add_child(_editor)
	_editor.setup()
	_make_visible(false)
	resource_saved.connect(_on_resource_saved)

func _exit_tree() -> void:
	_editor.queue_free()

func _has_main_screen() -> bool: return true
func _get_plugin_name() -> String: return "Adventure"
func _get_plugin_icon() -> Texture2D: return EditorInterface.get_editor_theme().get_icon("GraphEdit", "EditorIcons")
func _make_visible(visible: bool) -> void: _editor.visible = visible
func _handles(object: Object) -> bool: return object is Adventure

func _edit(object: Object) -> void:
	if object is Adventure: _editor.adventure = object as Adventure

func _get_window_layout(configuration: ConfigFile) -> void:
	if _editor.adventure != null: configuration.set_value("AdventureEditor", "adventure", _editor.adventure.resource_path)

func _set_window_layout(configuration: ConfigFile) -> void:
	var path: String = configuration.get_value("AdventureEditor", "adventure", "")
	if ResourceLoader.exists(path): _editor.adventure = load(path) as Adventure

func _on_resource_saved(resource: Resource) -> void:
	if not resource is AdventureLayout: _editor.rebuild()
