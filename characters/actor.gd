@abstract
class_name Actor
extends Node

## What characters and monsters share: breath dice, injuries and gear.

signal lost_breath(lost_breath_dice: Array[Die])
signal suffered_injury(injury: Injury)
signal injuries_changed(injuries: Array[Injury])
signal breath_dice_changed(breath_dice: Dictionary[Die, int])

var breath_dice: Dictionary[DieType, int] :
	set(new_breath_dice):
		if new_breath_dice == breath_dice: return
		breath_dice = new_breath_dice
		breath_dice_changed.emit(breath_dice)

var weapons: Array[Weapon] = []
var armor: Array[Armor] = []
var shields: Array[Shield] = []

# TODO: if you roll under an injury, increase magnitude by 1
var _injuries: Array[Injury] :
	set(new_injuries):
		if new_injuries == _injuries: return
		_injuries = new_injuries
		injuries_changed.emit(_injuries)

## The effective score: injuries already taken off
@abstract func get_score(attribute: CharacterAttribute) -> int
@abstract func get_actor_name() -> String
## How fight texts name it when it isn't the player: "the Lurker", "Dorian"
func get_reference() -> String: return get_actor_name()
## "its", "their"
func get_possessive_pronoun() -> String: return "their"

## The character or monster profile it is made from
@abstract func set_profile(profile: ActorProfile) -> void

func get_abilities() -> Array[Ability]: return []
## Claws, fangs and the like: its breath dice are its weapon dice
func has_natural_weapons() -> bool: return false
## What of [param lost_breath_dice] it actually loses (origins may spare some)
func get_lost_breath_dice(lost_breath_dice: Array[Die]) -> Array[Die]: return lost_breath_dice
## Names of the origins with an ability for which [param applies] (taking the [Ability]) holds, to tell what an ability did
func get_origin_names(_applies: Callable) -> Array[String]: return []
## Called as a fight against it starts
func prepare_for_fight() -> void: pass

func lose_breath_dice(lost_breath_dice: Array[Die]) -> void:
	if lost_breath_dice.is_empty(): return
	var new_breath_dice: Dictionary[DieType, int] = breath_dice.duplicate()
	for breath_die: Die in lost_breath_dice:
		new_breath_dice[breath_die.die_type] = new_breath_dice[breath_die.die_type] - 1
		assert(new_breath_dice[breath_die.die_type] >= 0)
	breath_dice = new_breath_dice
	lost_breath.emit(lost_breath_dice)

# TODO: injuries from outside fights (consequences) should also call for the incapacitation save; what being incapacitated means there is open
func suffer_injury(injury: Injury) -> void:
	assert(injury.magnitude > 0)
	_injuries.append(injury)
	injuries_changed.emit(_injuries)
	suffered_injury.emit(injury)

func get_injury_total() -> int:
	var total: int = 0
	for injury: Injury in _injuries: total += injury.magnitude
	return total

## Injuries brought at least one score to 0 or below: every further injury calls for a Guts save against all injuries
func is_overwhelmed_by_injuries() -> bool:
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: if get_score(attribute) <= 0: return true
	return false

## Picks up what the foe's Nerves made this actor drop
func pick_up_dropped_gear() -> void:
	for weapon: Weapon in weapons: weapon.dropped = false
	for shield: Shield in shields: shield.dropped = false

func get_breath_dice_count() -> int:
	var count: int = 0
	for amount: int in breath_dice.values(): count += amount
	return count

func is_out_of_breath() -> bool: return get_breath_dice_count() == 0

func get_breath_dice_pool() -> Array[Die]:
	return DiceRoller.generate_dice_pool(breath_dice)

## Breath dice, injuries and the state of carried gear, as plain values ([SaveGame]); gear by its place in the profile's lists
func get_save() -> Dictionary:
	var breath: Dictionary[String, int] = {}
	for die_type: DieType in breath_dice: breath[ResourceId.of(die_type)] = breath_dice[die_type]
	var injuries: Array[int] = []
	for injury: Injury in _injuries: injuries.append(injury.magnitude)
	return {breath_dice = breath, injuries = injuries, weapons = _save_gear(weapons), armor = _save_gear(armor), shields = _save_gear(shields)}

## After the profile is set (which hands out the gear)
func restore(data: Dictionary) -> void:
	var breath: Dictionary[DieType, int] = {}
	var saved_breath: Dictionary = data.breath_dice
	for id: String in saved_breath:
		var count: int = saved_breath[id]
		breath[ResourceId.find(id) as DieType] = count
	breath_dice = breath
	var injuries: Array[Injury] = []
	var magnitudes: Array = data.injuries
	for saved_magnitude: Variant in magnitudes:
		var magnitude: int = saved_magnitude
		injuries.append(Injury.new(magnitude))
	_injuries = injuries
	var saved_weapons: Array = data.weapons
	var saved_armor: Array = data.armor
	var saved_shields: Array = data.shields
	_restore_gear(weapons, saved_weapons)
	_restore_gear(armor, saved_armor)
	_restore_gear(shields, saved_shields)

static func _save_gear(gear: Array) -> Array[Dictionary]:
	var saved: Array[Dictionary] = []
	for equipment: Equipment in gear: saved.append({marked_faces = equipment.marked_faces.duplicate(), ruined = equipment.ruined})
	return saved

static func _restore_gear(gear: Array, saved: Array) -> void:
	assert(gear.size() == saved.size(), "The saved gear doesn't match the profile's")
	for index: int in gear.size():
		var equipment: Equipment = gear[index]
		var state: Dictionary = saved[index]
		var faces: Array = state.marked_faces
		equipment.marked_faces.clear()
		for saved_face: Variant in faces:
			var face: int = saved_face
			equipment.marked_faces.append(face)
		equipment.ruined = state.ruined
