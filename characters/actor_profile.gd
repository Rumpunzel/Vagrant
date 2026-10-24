@tool
@abstract
class_name ActorProfile
extends Resource

## What character and monster profiles share, so either can stand on a side of a fight

signal name_changed(name: String)

@export_placeholder("Name") var name: String:
	set(new_name):
		name = new_name
		name_changed.emit(name)
## [] = unarmed (monsters: natural weapons)
@export var weapons: Array[WeaponProfile] = []
@export var armor: Array[ArmorProfile] = []
## Only the first usable one is raised
@export var shields: Array[ShieldProfile] = []

## Applied to the gear when it is handed out, e.g. "battered"
@abstract func get_weapon_modifiers() -> Array[EquipmentModifier]
@abstract func get_armor_modifiers() -> Array[EquipmentModifier]
@abstract func get_shield_modifiers() -> Array[EquipmentModifier]
## The attribute score as profiled, before origins and injuries
@abstract func get_attribute_score(attribute: CharacterAttribute) -> int
## A copy with [param attribute] at [param score]; the profile itself is left as it is
@abstract func with_attribute_score(attribute: CharacterAttribute, score: int) -> ActorProfile
## Whether an actor can be made from it as it is (a character's attributes may not be rolled yet)
@abstract func can_fight() -> bool
## The character or monster scene for this profile; hand the profile to the instance with [method Actor.set_profile].
## Profiles must not name the actor classes: those reach [Rules], which the attribute and die resources load from.
@abstract func get_actor_scene() -> PackedScene
