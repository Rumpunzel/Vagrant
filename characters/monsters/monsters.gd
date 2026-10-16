class_name Monsters
extends Node

@export_group("Configuration")
@export var _monster_scene: PackedScene = preload("uid://kmifqq0ejuri")

## A monster is identified by the page that spawned it, its profile, and its index among
## monsters with the same profile on that page, since one profile can spawn many monsters.
## MonsterIndex.get_key() -> Monster
var monsters: Dictionary[Array, Monster] = { }

func get_monster(spawning_page: AdventurePage, monster_profile: MonsterProfile, index: int = 0) -> Monster:
	assert(spawning_page)
	assert(monster_profile)
	assert(index >= 0)
	var monster_index: MonsterIndex = MonsterIndex.new(spawning_page, monster_profile, index)
	var monster: Monster = monsters.get(monster_index.get_key())
	if monster: return monster
	monster = _monster_scene.instantiate()
	monster.monster_profile = monster_profile
	monster.name = "%s [%d]" % [monster.get_monster_name(), index]
	monsters[monster_index.get_key()] = monster
	add_child(monster, true)
	return monster

class MonsterIndex extends RefCounted:
	var spawning_page: AdventurePage
	var monster_profile: MonsterProfile
	var index: int
	
	func _init(for_spawning_page: AdventurePage, for_monster_profile: MonsterProfile, for_index: int) -> void:
		spawning_page = for_spawning_page
		monster_profile = for_monster_profile
		index = for_index

	## Arrays compare by value, objects by identity, so dictionaries are keyed by this
	func get_key() -> Array: return [spawning_page, monster_profile, index]
