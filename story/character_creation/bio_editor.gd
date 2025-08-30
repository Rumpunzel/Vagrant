@tool
class_name BioEditor
extends VBoxContainer

signal details_changed(character_name: String, portrait: Texture2D)

enum Sex {
	ANY,
	MALE,
	FEMALE,
}

@export_dir var _portraits_directory: String
@export var _portrait_pattern: String = "Fulllength.png$"
@export var _search_recursively: bool = true

@export_group("Sex")
@export var _icons: Dictionary[Sex, Texture2D] = {
	Sex.ANY: preload("uid://f8vbxu7etd2o"),
	Sex.MALE: preload("uid://cp642yk18khgp"),
	Sex.FEMALE: preload("uid://kxgb3pbscofy"),
}
@export var _patterns: Dictionary[Sex, String] = {
	Sex.ANY: ".*",
	Sex.MALE: "-M\\d+$",
	Sex.FEMALE: "-F\\d+$",
}
@export var _sex: Sex = Sex.ANY :
	set(new_sex):
		_sex = new_sex
		_sex_button._icon = _icons[_sex]
		_random_button.tooltip_text = "%d Portraits" % _portraits[_sex].size()
		if not _portraits[_sex].has(_portrait.texture): randomize_portrait()

@export_group("Configruation")
@export var _name: LineEdit
@export var _portrait: TextureRect
@export var _sex_button: HoverButton
@export var _random_button: HoverButton

var _compiled_portrait_pattern: RegEx
var _compiled_patterns: Dictionary[Sex, RegEx]

var _portraits: Dictionary[Sex, Array] = {}
var _portrait_directories: Dictionary[Texture2D, String] = {}
var _portrait_index: int = 0

func _ready() -> void:
	_compiled_portrait_pattern = RegEx.new()
	_compiled_portrait_pattern.compile(_portrait_pattern)
	for sex: Sex in Sex.values():
		var regex: RegEx = RegEx.new()
		regex.compile(_patterns[sex])
		_compiled_patterns[sex] = regex
	_load_portraits()
	randomize_portrait()

func randomize_portrait() -> void:
	var new_portrait: Texture2D = _portrait.texture
	while new_portrait == _portrait.texture: new_portrait = _portraits[_sex].pick_random()
	_set_portrait(new_portrait)

func appear() -> void:
	# TODO: animate this
	visible = true

func get_available_portraits(sex: Sex, directory_path: String = _portraits_directory) -> Dictionary[Texture2D, String]:
	var available_portraits: Dictionary[Texture2D, String] = {}
	var portraits_directory: DirAccess = DirAccess.open(directory_path)
	if not portraits_directory:
		printerr("Could not open portraits_directory at path: %s" % directory_path)
		return {}
	portraits_directory.list_dir_begin()
	var file_name: String = portraits_directory.get_next()
	while not file_name.is_empty():
		var file_path: String = directory_path.path_join(file_name)
		if portraits_directory.current_is_dir():
			if _search_recursively:
				var result: RegExMatch = _compiled_patterns[sex].search(file_name)
				if result: available_portraits.merge(get_available_portraits(sex, file_path))
		else:
			var result: RegExMatch = _compiled_portrait_pattern.search(file_name)
			if result:
				var portrait: Texture2D = load(file_path)
				assert(portrait is Texture2D)
				available_portraits[portrait] = file_path
		file_name = portraits_directory.get_next()
	return available_portraits

func _load_portraits() -> void:
	_portraits.clear()
	_portrait_directories.clear()
	for sex: Sex in Sex.values():
		var available_portraits: Dictionary[Texture2D, String] = get_available_portraits(sex)
		_portrait_directories.merge(available_portraits)
		_portraits[sex] = available_portraits.keys()
	_random_button.tooltip_text = "%d Portraits" % _portraits[_sex].size()

func _set_portrait(new_portrait: Texture2D) -> void:
	_portrait.texture = new_portrait
	_portrait.tooltip_text = _portrait_directories[new_portrait]
	_portrait_index = _portraits[_sex].find(new_portrait)
	details_changed.emit(_name.text, _portrait.texture)

func _on_name_changed(new_text: String) -> void:
	details_changed.emit(new_text, _portrait.texture)

func _on_sex_pressed() -> void:
	_sex = (_sex + 1) % Sex.size() as Sex

func _on_previous_pressed() -> void:
	_portrait_index = (_portrait_index - 1 + _portraits[_sex].size()) % _portraits[_sex].size()
	var portrait: Texture2D = _portraits[_sex][_portrait_index]
	_set_portrait(portrait)

func _on_next_pressed() -> void:
	_portrait_index = (_portrait_index + 1) % _portraits[_sex].size()
	var portrait: Texture2D = _portraits[_sex][_portrait_index]
	_set_portrait(portrait)

func _on_random_pressed() -> void:
	randomize_portrait()

func _on_character_name_changed(character_name: String) -> void:
	_name.text = character_name

func _on_portrait_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton: return
	var mouse_event: InputEventMouseButton = event
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.double_click:
		var global_portrait_path: String = ProjectSettings.globalize_path(_portrait_directories[_portrait.texture])
		OS.shell_show_in_file_manager(global_portrait_path)
