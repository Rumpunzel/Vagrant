@tool
class_name TypingLabel
extends RichTextLabel

## This is an extended RichTextLabel that supports a bunch more functionality for typing out text, including different typing speeds and pauses

signal finished_typing

@export var _characters_per_minute := 4000.0

## Definition of all used punctuation which will cause a brief pause when typing out the message
@export var _pause_multipliers := {
	".": 16.0,
	"?": 16.0,
	"!": 16.0,
	":": 12.0, 
	";": 12.0,
	"…": 24.0,
	"—": 8.0, 
	",": 8.0, 
}

var _typing_timer: Timer

func _enter_tree() -> void:
	_typing_timer = Timer.new()
	add_child(_typing_timer, false, Node.INTERNAL_MODE_BACK)
	_typing_timer.one_shot = true
	_typing_timer.timeout.connect(_type_next_character)

# Type out the text while briefly pausing for punctuation
func _process(delta: float) -> void:
	if not Engine.is_editor_hint() and Input.is_action_just_pressed("skip_dialog"):
		visible_characters = -1

## To use this script, simply call this method from anywhere with the text you want it to type
func type_text(new_text: String):
	text = new_text
	if text.is_empty() or _characters_per_minute <= 0:
		visible_characters = -1
	else:
		visible_characters = 0
		_type_next_character()

func _type_next_character():
	var parsed_text := get_parsed_text()
	var typed_character := parsed_text[visible_characters]
	print("typed_character: %s" % typed_character)
	visible_characters += 1
	if visible_characters >= parsed_text.length():
		print("here")  
		finished_typing.emit()
		return
	var pause_multiplier: float = _pause_multipliers.get(typed_character, 1.0)
	var type_delay := 60.0 / _characters_per_minute * pause_multiplier
	print("type_delay: %f" % type_delay)
	_typing_timer.start(type_delay)
