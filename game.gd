class_name Game
extends Node

@export var _default_adventure: AdventureTome
@export var _character_creation: PackedScene
@export var _adventure: PackedScene

@export_group("Configuration")
@export var _story: Story
@export var _characters: Characters
@export var _stage: Stage
@export var _game: Control

func _ready() -> void:
	_enter_character_creation()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_released("debug_restart"):
		get_viewport().set_input_as_handled()
		var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
		get_tree().change_scene_to_file(main_scene)

func _enter_character_creation() -> void:
	_clean_game()
	var character_creation: CharacterCreation = _character_creation.instantiate()
	character_creation.character_created.connect(_on_character_created)
	_game.add_child(character_creation)

func _enter_adventure(protagonist_profile: CharacterProfile) -> void:
	_clean_game()
	_characters.create_character(protagonist_profile)
	var adventure: Adventure = _adventure.instantiate()
	adventure.story_book_page_entered.connect(_stage.set_story_page)
	_game.add_child(adventure)
	adventure.setup(_story, _characters, _default_adventure)
	_story.start_adventure(adventure)

func _clean_game() -> void:
	while _game.get_child_count() > 0:
		var child: Node = _game.get_child(0)
		_game.remove_child(child)
		child.queue_free()

func _on_character_created(character_profile: CharacterProfile) -> void:
	_characters.protagonist_profile = character_profile
	_enter_adventure(character_profile)
