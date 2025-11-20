extends Node

var _main_scene_path: String = ProjectSettings.get_setting("application/run/main_scene")
var _character_creation_scene_path: String = "uid://cc3qx1qt3ie00"
var _story_scene_path: String = "uid://db6oui711vqep"

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	var mouse_event: InputEventMouseButton = event
	if mouse_event.is_released():
		var viewport: Viewport = get_viewport()
		viewport.gui_release_focus()
		viewport.set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	var scene_tree: SceneTree = get_tree()
	var viewport: Viewport = get_viewport()
	if event.is_action_released("debug_restart"):
		viewport.set_input_as_handled()
		var main_scene: PackedScene = Files.load_async(_main_scene_path)
		scene_tree.change_scene_to_packed(main_scene)
	elif event.is_action_released("debug_restart_story"):
		if not scene_tree.current_scene is Story: printerr("Cannot restart Story!")
		else:
			viewport.set_input_as_handled()
			var current_story: Story = scene_tree.current_scene
			_enter_story(current_story.adventure, current_story.protagonist.character_profile)

func enter_character_creation(protagonist: CharacterProfile) -> CharacterCreation:
	var scene_tree: SceneTree = get_tree()
	var character_creation_scene: PackedScene = Files.load_async(_character_creation_scene_path)
	scene_tree.change_scene_to_packed(character_creation_scene)
	await scene_tree.scene_changed
	assert(scene_tree.current_scene is CharacterCreation)
	var character_creation: CharacterCreation = scene_tree.current_scene
	character_creation.character_profile = protagonist
	return character_creation

func enter_story(adventure: Adventure) -> Story:
	ResourceLoader.load_threaded_request(_story_scene_path)
	var protagonist: CharacterProfile = adventure.protagonist.duplicate(true) # Duplicate to be able to be reset on restart
	if not protagonist or not protagonist.is_valid():
		var character_creation: CharacterCreation = await enter_character_creation(protagonist)
		await character_creation.character_created
	return await _enter_story(adventure, protagonist)

func _enter_story(adventure: Adventure, protagonist: CharacterProfile) -> Story:
	var scene_tree: SceneTree = get_tree()
	var story_scene: PackedScene = Files.load_async(_story_scene_path)
	scene_tree.change_scene_to_packed(story_scene)
	await scene_tree.scene_changed
	assert(scene_tree.current_scene is Story)
	var story: Story = scene_tree.current_scene
	story.start_adventure(adventure, protagonist)
	return story
