extends GdUnitTestSuite

## Runtime state comes back from a save (through JSON) as it was: characters, monsters, the world, the journal; saves that name something
## gone, or come from another version, can't be loaded.

const CHARACTER: String = "uid://bl0pdxri24fnh"  # character.tscn
const DIRECTORY: String = "user://save_state_test"

func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)

func after_test() -> void:
	for file: String in DirAccess.get_files_at(DIRECTORY): DirAccess.remove_absolute(DIRECTORY.path_join(file))
	DirAccess.remove_absolute(DIRECTORY)
	if FileAccess.file_exists(SaveGame.get_path_of("save_state_test")): DirAccess.remove_absolute(SaveGame.get_path_of("save_state_test"))

func test_character_comes_back() -> void:
	var origin: Origin = _saved(TestCharacters.origin("Wanderer"), "origin")
	var item: ItemProfile = _saved(ItemProfile.new(), "item")
	var knife: Array[WeaponProfile] = TestMonsters.cutthroat().weapons
	var profile: CharacterProfile = TestCharacters.adventurer()
	profile.name = "Mira"
	profile.title = "the Lost"
	profile.origins = [origin, null] as Array[Origin]
	profile.attribute_scores[Rules.AGILITY] = TestCharacters.rolled(5, 6)
	profile.weapons = knife
	var character: Character = _character(profile)
	character.breath_dice = {Rules.d4: 1, Rules.d6: 2}
	character.suffer_injury(Injury.new(2))
	character.exhaustion = [Rules.d8] as Array[DieType]
	character.weapons[0].marked_faces = [3, 5] as Array[int]
	character.weapons[0].ruined = true
	character.items[item] = 3
	character.most_recently_chosen_attribute = Rules.INTELLIGENCE
	var data: Dictionary = _through_json(character.get_save())

	var copy_profile: CharacterProfile = TestCharacters.adventurer()
	copy_profile.weapons = knife
	var saved_profile: Dictionary = data.profile
	Character.restore_profile(copy_profile, saved_profile)
	var copy: Character = _character(copy_profile)
	copy.restore(data)
	assert_str(copy_profile.name).is_equal("Mira")
	assert_str(copy_profile.title).is_equal("the Lost")
	assert_array(copy_profile.origins).contains_exactly([origin, null])
	assert_int(copy_profile.get_attribute_score(Rules.AGILITY)).is_equal(profile.get_attribute_score(Rules.AGILITY))
	assert_int(copy_profile.get_attribute_score(Rules.STRENGTH)).is_equal(profile.get_attribute_score(Rules.STRENGTH))
	assert_dict(copy.breath_dice).is_equal({Rules.d4: 1, Rules.d6: 2})
	assert_int(copy.get_injury_total()).is_equal(2)
	assert_array(copy.exhaustion).contains_exactly([Rules.d8])
	assert_array(copy.weapons[0].marked_faces).contains_exactly([3, 5])
	assert_bool(copy.weapons[0].ruined).is_true()
	assert_dict(copy.items).is_equal({item: 3})
	assert_object(copy.most_recently_chosen_attribute).is_same(Rules.INTELLIGENCE)

func test_monsters_come_back() -> void:
	var encounter: AdventureEncounter = _saved(AdventureEncounter.new(), "encounter")
	var page: AdventurePage = _saved(AdventurePage.new(), "page")
	var location: AdventureLocation = _saved(AdventureLocation.new(), "location")
	var cutthroat: MonsterProfile = _saved(TestMonsters.cutthroat(), "cutthroat")
	var monsters: Monsters = auto_free(Monsters.new())
	add_child(monsters)
	var hurt: Monster = monsters.get_monster(encounter, cutthroat)
	hurt.suffer_injury(Injury.new(3))
	hurt.incapacitated = true
	monsters.get_monster(page, cutthroat, 0, location)
	var second: Monster = monsters.get_monster(page, cutthroat, 1, location)
	second.dead = true
	var saved: Array = _through_json(monsters.get_save())

	var copy: Monsters = auto_free(Monsters.new())
	add_child(copy)
	copy.restore(saved)
	assert_int(copy.get_monster(encounter, cutthroat).get_injury_total()).is_equal(3)
	assert_bool(copy.get_monster(encounter, cutthroat).incapacitated).is_true()
	assert_bool(copy.get_monster(page, cutthroat, 0, location).dead).is_false()
	assert_bool(copy.get_monster(page, cutthroat, 1, location).dead).is_true()

func test_world_comes_back() -> void:
	var encounter: AdventureEncounter = _saved(AdventureEncounter.new(), "encounter")
	var location: AdventureLocation = _saved(AdventureLocation.new(), "location")
	var world: StoryWorld = StoryWorld.new()
	world.set_stage(encounter, "Mood", "angry")
	world.set_stage(location, "Door", "open")
	world.move(encounter, [location] as Array[AdventureLocation])
	var copy: StoryWorld = StoryWorld.new()
	var saved_world: Dictionary = _through_json(world.get_save())
	copy.restore(saved_world)
	assert_str(copy.get_stage(encounter, "Mood")).is_equal("angry")
	assert_str(copy.get_stage(location, "Door")).is_equal("open")
	assert_array(copy.get_places(encounter)).contains_exactly([location])

func test_journal_counts_come_back() -> void:
	var page: AdventurePage = _saved(AdventurePage.new(), "page")
	var decision: AdventureDecision = _saved(AdventureDecision.new(), "decision")
	var journal: StoryJournal = StoryJournal.new()
	journal.enter(page)
	journal.choose(decision)
	journal.enter(page)
	var copy: StoryJournal = StoryJournal.new()
	var saved_entries: Array = _through_json(journal.entries)
	copy.restore(saved_entries)
	assert_int(copy.get_times_entered(page)).is_equal(2)
	assert_int(copy.get_times_made(decision)).is_equal(1)
	assert_array(copy.entries).has_size(3)

func test_save_game_written_and_read() -> void:
	var page: AdventurePage = _saved(AdventurePage.new(), "page")
	var save_game: SaveGame = SaveGame.new()
	save_game.run = "save_state_test"
	save_game.story = {page = ResourceId.of(page), random = {state = "-123456789012345678"}}
	assert_int(save_game.write()).is_equal(OK)
	var read: SaveGame = SaveGame.read("save_state_test")
	assert_dict(read.story).is_equal(save_game.story)
	assert_array(read.get_problems()).is_empty()
	assert_array(SaveGame.get_runs()).contains(["save_state_test"])
	assert_object(SaveGame.read("save_state_test_none")).is_null()

## Written next to the slot first, then put in its place
func test_save_game_replaces_its_slot() -> void:
	var save_game: SaveGame = SaveGame.new()
	save_game.run = "save_state_test"
	save_game.story = {page = "first"}
	assert_int(save_game.write()).is_equal(OK)
	save_game.story = {page = "second"}
	assert_int(save_game.write()).is_equal(OK)
	assert_dict(SaveGame.read("save_state_test").story).is_equal({page = "second"})
	assert_bool(FileAccess.file_exists(SaveGame.get_path_of("save_state_test") + ".tmp")).is_false()

func test_deleting_a_run() -> void:
	var save_game: SaveGame = SaveGame.new()
	save_game.run = "save_state_test"
	assert_int(save_game.write()).is_equal(OK)
	SaveGame.delete_run("save_state_test")
	assert_array(SaveGame.get_runs()).not_contains(["save_state_test"])

func test_refuses_what_is_gone() -> void:
	var save_game: SaveGame = SaveGame.new()
	save_game.story = {page = DIRECTORY.path_join("gone.tres"), stack = ["uid://bxxxxxxxxxxxx"]}
	assert_array(save_game.get_problems()).has_size(2)
	# What is gone from the history doesn't keep a save from loading
	var page: AdventurePage = _saved(AdventurePage.new(), "page")
	save_game.story = {page = ResourceId.of(page), journal = [{type = "enter", page = "uid://bxxxxxxxxxxxx"}], book = [{background = "uid://bxxxxxxxxxxxx"}]}
	assert_array(save_game.get_problems()).is_empty()
	save_game.story = {}
	assert_array(save_game.get_problems()).has_size(1)

## Saved to a file and loaded back, so it has an ID
func _saved(resource: Resource, file_name: String) -> Resource:
	var path: String = DIRECTORY.path_join(file_name + ".tres")
	ResourceSaver.save(resource, path)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)

func _character(profile: CharacterProfile) -> Character:
	var scene: PackedScene = load(CHARACTER)
	var character: Character = auto_free(scene.instantiate())
	add_child(character)
	character.character_profile = profile
	return character

static func _through_json(data: Variant) -> Variant: return JSON.parse_string(JSON.stringify(data))
