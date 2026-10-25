class_name Monsters
extends Node

@export_group("Configuration")
@export var _monster_scene: PackedScene = preload("uid://kmifqq0ejuri")

## { [spawning page, host or null] -> Array[Monster] }; a host only for generic events, whose hosts each get their own
var monsters: Dictionary[Array, Array] = { }

## { MonsterProfile -> Array[Monster] }
var _monsters_by_profile: Dictionary[MonsterProfile, Array] = { }

func get_monster(spawning_page: AdventurePage, monster_profile: MonsterProfile, index: int = 0, host: AdventurePage = null) -> Monster:
	assert(spawning_page)
	assert(monster_profile)
	assert(index >= 0)
	var monsters_from_page: Array[Monster] = monsters.get([spawning_page, host], [] as Array[Monster])
	var fitting_monsters: Array[Monster] = []
	fitting_monsters.assign(monsters_from_page.filter(func(monster: Monster) -> bool: return monster.monster_profile == monster_profile))
	if index == fitting_monsters.size(): return _spawn_monster(spawning_page, monster_profile, index, host)
	assert(index < fitting_monsters.size(), "Invalid monster spawn index!")
	return fitting_monsters[index]

func get_all_monsters_of_type(monster_profile: MonsterProfile) -> Array[Monster]:
	return _monsters_by_profile.get(monster_profile, [] as Array[Monster])

func _spawn_monster(spawning_page: AdventurePage, monster_profile: MonsterProfile, index: int, host: AdventurePage) -> Monster:
	var monster: Monster = _monster_scene.instantiate()
	monster.monster_profile = monster_profile
	monster.name = "%s [%d]" % [monster.get_monster_name(), index]
	monster.spawned_from = spawning_page
	var monsters_from_page: Array[Monster] = monsters.get([spawning_page, host], [] as Array[Monster])
	monsters_from_page.append(monster)
	monsters[[spawning_page, host]] = monsters_from_page
	var monsters_by_profile: Array[Monster] = _monsters_by_profile.get(monster_profile, [] as Array[Monster])
	monsters_by_profile.append(monster)
	_monsters_by_profile[monster_profile] = monsters_by_profile
	add_child(monster, true)
	return monster
