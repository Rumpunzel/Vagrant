@tool
class_name BioEditor
extends VBoxContainer

signal details_changed(character_name: String, title: String, portrait: Texture2D)

enum Sex {
	ANY,
	MALE,
	FEMALE,
}

@export_dir var _portraits_directory: String
@export var _portrait_file_name: String = "Fulllength.png"
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
		_sex_button.tooltip_text = "%d Portraits" % _portrait_directories[_sex].size()
		_random_button.tooltip_text = "%d Portraits" % _portrait_directories[_sex].size()
		randomize_portrait()

@export_group("Configruation")
@export var _name: LineEdit
@export var _title: LineEdit
@export var _portrait: TextureRect
@export var _sex_button: HoverButton
@export var _random_button: HoverButton

var _compiled_portrait_pattern: RegEx
var _compiled_patterns: Dictionary[Sex, RegEx]

# Dictionary[Sex, Array[String]]
var _portrait_directories: Dictionary[Sex, Array] = {}
var _portrait_index: int = 0 :
	set(new_portrait_index):
		_portrait_index = new_portrait_index
		_portrait_index %= _portrait_directories[_sex].size()
		var directory_path: String = _portrait_directories[_sex][_portrait_index]
		var portrait_path: String = directory_path.path_join(_portrait_file_name)
		var portrait: Texture2D = load(portrait_path)
		_portrait.texture = portrait
		_portrait.tooltip_text = portrait_path
		details_changed.emit(_name.text, _title.text, _portrait.texture)

func _ready() -> void:
	_compiled_portrait_pattern = RegEx.new()
	for sex: Sex in Sex.values():
		var regex: RegEx = RegEx.new()
		regex.compile(_patterns[sex])
		_compiled_patterns[sex] = regex
	_load_portraits()
	randomize_portrait()

func randomize_portrait() -> void:
	var new_portrait_index: int = _portrait_index
	while new_portrait_index == _portrait_index: new_portrait_index = randi_range(0, _portrait_directories[_sex].size() - 1)
	_portrait_index = new_portrait_index

func appear() -> void:
	# TODO: animate this
	visible = true

func _load_portraits() -> void:
	_portrait_directories.clear()
	for sex: Sex in Sex.values():
		var portrait_directories: Array[String] = Rules.list_all_directories(_portraits_directory, _search_recursively, func(directory_name: String) -> bool: return _compiled_patterns[sex].search(directory_name) != null)
		_portrait_directories[sex] = portrait_directories
	_sex_button.tooltip_text = "%d Portraits" % _portrait_directories[_sex].size()
	_random_button.tooltip_text = "%d Portraits" % _portrait_directories[_sex].size()

func _on_name_changed(new_text: String) -> void:
	details_changed.emit(new_text, _title.text, _portrait.texture)

func _on_title_changed(_new_text: String) -> void:
	details_changed.emit(_name.text, _title.text, _portrait.texture)

func _on_sex_pressed() -> void:
	_sex = (_sex + 1) % Sex.size() as Sex

func _on_previous_pressed() -> void:
	_portrait_index -= 1

func _on_next_pressed() -> void:
	_portrait_index += 1

func _on_random_pressed() -> void:
	randomize_portrait()

func _on_character_name_changed(character_name: String) -> void:
	_name.text = character_name

func _on_character_title_changed(character_title: String) -> void:
	_title.text = character_title

func _on_origins_picked(origins: Array[Origin]) -> void:
	_title.placeholder_text = Origin.concatenate(origins)

func _on_portrait_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton: return
	var mouse_event: InputEventMouseButton = event
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.double_click:
		var portrait_path: String = _portrait_directories[_sex][_portrait_index]
		var global_portrait_path: String = ProjectSettings.globalize_path(portrait_path)
		OS.shell_show_in_file_manager(global_portrait_path)
