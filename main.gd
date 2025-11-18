extends Node

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	var mouse_event: InputEventMouseButton = event
	if mouse_event.is_released():
		get_viewport().gui_release_focus()
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_released("debug_restart"):
		get_viewport().set_input_as_handled()
		var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
		get_tree().change_scene_to_file(main_scene)

func enter_character_creation(protagonist: CharacterProfile) -> void:
	var scene_tree: SceneTree = get_tree()
	scene_tree.change_scene_to_file("uid://cc3qx1qt3ie00")
	await scene_tree.scene_changed
	assert(scene_tree.current_scene is CharacterCreation)
	var character_creation: CharacterCreation = scene_tree.current_scene
	character_creation.character_profile = protagonist
	await character_creation.character_created

func enter_story(adventure: Adventure) -> void:
	var protagonist: CharacterProfile = adventure.protagonist
	if not protagonist or not protagonist.is_valid(): await enter_character_creation(protagonist)
	_enter_story(adventure, protagonist)

func _enter_story(adventure: Adventure, protagonist: CharacterProfile) -> void:
	var scene_tree: SceneTree = get_tree()
	scene_tree.change_scene_to_file("uid://db6oui711vqep")
	await scene_tree.scene_changed
	assert(scene_tree.current_scene is Story)
	var story: Story = scene_tree.current_scene
	story.start_adventure(adventure, protagonist)
