@tool
class_name TypingLabel
extends RichTextLabel

## This is an extended RichTextLabel that supports a bunch more functionality for typing out text, including different typing speeds and pauses

signal finished_typing
signal finished_erasing

## Definition of all used punctuation which will cause a brief pause when typing out the message
const _PAUSE_MULTIPLIERS := {
	".": 16.0,
	"?": 16.0,
	"!": 16.0,
	":": 12.0, 
	";": 12.0,
	"…": 24.0,
	"—": 8.0, 
	",": 4.0,
	"\n": 16.0,
}

@export var _characters_per_minute := 4000.0
@export var _erase_multiplier := 2.0
@export var _pause_after_erase_multiplier := 8.0

var _text_to_type: String
var _typing_timer: Timer
var _erasing_timer: Timer

func _enter_tree() -> void:
	_typing_timer = Timer.new()
	_erasing_timer = Timer.new()
	add_child(_typing_timer, false, Node.INTERNAL_MODE_BACK)
	add_child(_erasing_timer, false, Node.INTERNAL_MODE_BACK)
	_typing_timer.one_shot = true
	_erasing_timer.one_shot = true
	_typing_timer.timeout.connect(_type_next_character)
	_erasing_timer.timeout.connect(_erase_previous_character)

func _process(_delta: float) -> void:
	if visible_ratio >= 1.0: return
	if Input.is_action_pressed("skip_dialog_typing"):
		set_text_normally(_text_to_type)

## To use this script, simply call this method from anywhere with the text you want it to type
func type_text(new_text: String, erase_text_first := false):
	if _characters_per_minute <= 0:
		set_text_normally(new_text)
		return
	_text_to_type = new_text
	if erase_text_first:
		visible_characters = get_parsed_text().length()
		_erase_previous_character()
	else:
		text = _text_to_type
		visible_characters = 0
		_type_next_character()

func set_text_normally(new_text: String) -> void:
	_text_to_type = new_text
	text = _text_to_type
	visible_characters = -1
	_typing_timer.stop()
	_erasing_timer.stop()
	finished_typing.emit()

func _type_next_character():
	var parsed_text := get_parsed_text()
	if visible_characters >= parsed_text.length():
		finished_typing.emit()
		return
	var next_character := parsed_text[visible_characters]
	visible_characters += 1
	var pause_multiplier: float = _PAUSE_MULTIPLIERS.get(next_character, 1.0)
	var type_delay := 60.0 / _characters_per_minute * pause_multiplier
	_typing_timer.start(type_delay)

func _erase_previous_character():
	var parsed_text := get_parsed_text()
	var parsed_text_to_type := _strip_bbcode(_text_to_type)
	var visible_previous_text := parsed_text.substr(0, visible_characters)
	if parsed_text_to_type.begins_with(visible_previous_text):
		finished_erasing.emit()
		text = _text_to_type
		var type_delay := 60.0 / _characters_per_minute * _pause_after_erase_multiplier
		_typing_timer.start(type_delay)
		return
	visible_characters -= 1
	var erase_delay := 60.0 / _characters_per_minute / _erase_multiplier
	_erasing_timer.start(erase_delay)

func _strip_bbcode(source:String) -> String:
	var regex := RegEx.new()
	regex.compile("\\[.+?\\]")
	return regex.sub(source, "", true)
