@tool
class_name StoryCombatPage
extends StoryPage

@export var enemies: Array[MonsterProfile]

func create() -> PageEntry:
	var combat_entry_scene: PackedScene = load("uid://bsivsd7uc6f0f")
	var combat_entry: PageEntry = combat_entry_scene.instantiate()
	return combat_entry
