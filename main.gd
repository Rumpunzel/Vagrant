extends Node

const SUCCESS: Color = Color("#4F9C3E")
const FAILURE: Color = Color("#751A1F")
const INFO: Color = Color("#7C71A2")

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
		viewport.set_input_as_handled()
		restart_story()
	elif event.is_action_released("debug_continue_run"):
		viewport.set_input_as_handled()
		var runs: Array[String] = SaveGame.get_runs()
		if runs.is_empty(): printerr("No saved run to continue!")
		else: continue_run(runs[-1])

## The running story's adventure from the start, with the same protagonist (a new run); [param random_seed]: its random numbers
## (e.g. a logged run's seed), 0: new ones
func restart_story(random_seed: int = 0) -> void:
	var current_story: Story = get_tree().current_scene as Story
	if current_story == null:
		printerr("Cannot restart Story!")
		return
	GameRandom.next_seed = random_seed
	_enter_story(current_story._adventure, current_story.get_protagonist().character_profile)

func enter_character_creation(protagonist: CharacterProfile) -> CharacterCreation:
	var scene_tree: SceneTree = get_tree()
	var character_creation_scene: PackedScene = Files.load_async(_character_creation_scene_path)
	scene_tree.change_scene_to_packed(character_creation_scene)
	await scene_tree.scene_changed
	assert(scene_tree.current_scene is CharacterCreation)
	var character_creation: CharacterCreation = scene_tree.current_scene
	character_creation.character_profile = protagonist
	return character_creation

func enter_story(adventure: Adventure, page: AdventurePage = null, host: AdventurePage = null, forced: AdventureEvent = null) -> Story:
	ResourceLoader.load_threaded_request(_story_scene_path)
	var protagonist: CharacterProfile = adventure.protagonist.duplicate(true) # Duplicate to be able to be reset on restart
	if not protagonist or not protagonist.is_valid():
		var character_creation: CharacterCreation = await enter_character_creation(protagonist)
		await character_creation.character_created
	return await _enter_story(adventure, protagonist, page, host, forced)

func _enter_story(adventure: Adventure, protagonist: CharacterProfile, page: AdventurePage = null, host: AdventurePage = null, forced: AdventureEvent = null) -> Story:
	var scene_tree: SceneTree = get_tree()
	var story_scene: PackedScene = Files.load_async(_story_scene_path)
	scene_tree.change_scene_to_packed(story_scene)
	await scene_tree.scene_changed
	assert(scene_tree.current_scene is Story)
	var story: Story = scene_tree.current_scene
	# Only runs from the start are saved, not "Play from here" (which starts on a page)
	if page == null: story.run = SaveGame.start_run()
	story.start_adventure(adventure, protagonist, page, host, forced)
	return story

## Goes on with a saved run; null if it can't be loaded (the reasons are logged)
func continue_run(run: String) -> Story:
	var save_game: SaveGame = SaveGame.read(run)
	var problems: Array[String] = save_game.get_problems() if save_game != null else ["No such save."] as Array[String]
	if not problems.is_empty():
		push_warning("Run %s can't be loaded:\n%s" % [run, "\n".join(problems)])
		return null
	var adventure: Adventure = ResourceId.find_at(save_game.story, "adventure") as Adventure
	var scene_tree: SceneTree = get_tree()
	ResourceLoader.load_threaded_request(_story_scene_path)
	var story_scene: PackedScene = Files.load_async(_story_scene_path)
	scene_tree.change_scene_to_packed(story_scene)
	await scene_tree.scene_changed
	var story: Story = scene_tree.current_scene
	story.restore(adventure, run, save_game.story)
	return story
