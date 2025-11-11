@tool
class_name StoryCombatPage
extends StoryPage

@export var enemies: Array[MonsterProfile]

func create() -> PageEntry:
	var combat_entry_scene: PackedScene = load("uid://bsivsd7uc6f0f")
	var combat_entry: PageEntry = combat_entry_scene.instantiate()
	return combat_entry

func create_fight_request(story: Story, characters: Characters) -> FightRequest:
	return FightRequest.create_fight_request(get_description(story), characters.get_protagonist(), enemies)
