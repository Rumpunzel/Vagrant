@abstract
class_name Actor
extends Node

## What characters and monsters share: breath dice, injuries and what they carry: gear as pieces (each with its own marks), plain items
## in a number ([method gain], [method lose], [method count_of]).

signal lost_breath(lost_breath_dice: Array[Die])
signal suffered_injury(injury: Injury)
signal injuries_changed(injuries: Array[Injury])
signal breath_dice_changed(breath_dice: Dictionary[Die, int])
## Something was gained or lost
signal carried_changed

var breath_dice: Dictionary[DieType, int] :
	set(new_breath_dice):
		if new_breath_dice == breath_dice: return
		breath_dice = new_breath_dice
		breath_dice_changed.emit(breath_dice)

var weapons: Array[Weapon] = []
var armor: Array[Armor] = []
var shields: Array[Shield] = []
## Plain items carried -> how many; gear is carried as pieces in [member weapons], [member armor] and [member shields]
var items: Dictionary[ItemProfile, int] = {}

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

func get_injuries() -> Array[Injury]: return _injuries.duplicate()

func get_injury_total() -> int:
	var total: int = 0
	for injury: Injury in _injuries: total += injury.magnitude
	return total

## Injuries brought at least one score to 0 or below: every further injury calls for a Guts save against all injuries
func is_overwhelmed_by_injuries() -> bool:
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: if get_score(attribute) <= 0: return true
	return false

## Carries [param count] more of [param item]: gear as fresh pieces, anything else in its number
func gain(item: ItemProfile, count: int = 1) -> void:
	if count <= 0: return
	if item.is_gear():
		for _piece: int in count: _add_piece(_make_piece(item))
	else: items[item] = items.get(item, 0) + count
	carried_changed.emit()

## Gives up to [param count] of [param item]; returns how many it gave. Of gear, the most worn usable pieces go first; ruined ones don't count.
func lose(item: ItemProfile, count: int = 1) -> int:
	var lost: int = 0
	if item.is_gear():
		var pieces: Array[Equipment] = _get_pieces(item)
		pieces.sort_custom(func(a: Equipment, b: Equipment) -> bool: return a.marked_faces.size() > b.marked_faces.size())
		for piece: Equipment in pieces.slice(0, count): _remove_piece(piece)
		lost = mini(count, pieces.size())
	else:
		var item_count: int = items.get(item, 0)
		lost = mini(count, item_count)
		if lost == items.get(item, 0): items.erase(item)
		elif lost > 0: items[item] -= lost
	if lost > 0: carried_changed.emit()
	return lost

## Gives [param piece] to [param to] as it is, marks and all (taken off a beaten foe)
func hand_over(piece: Equipment, to: Actor) -> void:
	_remove_piece(piece)
	carried_changed.emit()
	to._add_piece(piece)
	to.carried_changed.emit()

## How many of [param item] are carried: plain items by their number, gear by its usable (not ruined) pieces
func count_of(item: ItemProfile) -> int:
	return _get_pieces(item).size() if item.is_gear() else items.get(item, 0)

## The usable (not ruined) pieces of gear made from [param item]
func _get_pieces(item: ItemProfile) -> Array[Equipment]:
	var pieces: Array[Equipment] = []
	for piece: Equipment in get_gear(): if piece.get_item_profile() == item and not piece.ruined: pieces.append(piece)
	return pieces

## Every piece of gear carried: weapons, armour, shields
func get_gear() -> Array[Equipment]:
	var gear: Array[Equipment] = []
	gear.append_array(weapons)
	gear.append_array(armor)
	gear.append_array(shields)
	return gear

static func _make_piece(item: ItemProfile) -> Equipment:
	if item is WeaponProfile: return Weapon.create(item as WeaponProfile)
	if item is ArmorProfile: return Armor.create(item as ArmorProfile)
	return Shield.create(item as ShieldProfile)

func _add_piece(piece: Equipment) -> void:
	if piece is Weapon: weapons.append(piece as Weapon)
	elif piece is Armor: armor.append(piece as Armor)
	elif piece is Shield: shields.append(piece as Shield)

func _remove_piece(piece: Equipment) -> void:
	if piece is Weapon: weapons.erase(piece)
	elif piece is Armor: armor.erase(piece)
	elif piece is Shield: shields.erase(piece)

func get_breath_dice_count() -> int:
	var count: int = 0
	for amount: int in breath_dice.values(): count += amount
	return count

func is_out_of_breath() -> bool: return get_breath_dice_count() == 0

func get_breath_dice_pool() -> Array[Die]:
	return DiceRoller.generate_dice_pool(breath_dice)

## Breath dice, injuries and the carried gear, as plain values ([SaveGame]): each piece by its profile, with its marks
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
	weapons.assign(_restore_gear(weapons, saved_weapons))
	armor.assign(_restore_gear(armor, saved_armor))
	shields.assign(_restore_gear(shields, saved_shields))
	carried_changed.emit()

static func _save_gear(gear: Array) -> Array[Dictionary]:
	var saved: Array[Dictionary] = []
	for equipment: Equipment in gear: saved.append({profile = ResourceId.of(equipment.get_item_profile()), marked_faces = equipment.marked_faces.duplicate(), ruined = equipment.ruined})
	return saved

## The pieces [param saved] lists, in its order. Each by its profile; one made at runtime (no ID), or a save from before gear could change
## during a run (no profiles), takes the piece at its place among those handed out ([param handed_out])
static func _restore_gear(handed_out: Array, saved: Array) -> Array[Equipment]:
	var pieces: Array[Equipment] = []
	for index: int in saved.size():
		var state: Dictionary = saved[index]
		var id: String = state.get("profile", "")
		var profile: ItemProfile = ResourceId.find(id) as ItemProfile if not id.is_empty() else null
		var piece: Equipment = _make_piece(profile) if profile != null and profile.is_gear() else null
		if piece == null and index < handed_out.size(): piece = handed_out[index]
		if piece == null: continue
		var faces: Array = state.marked_faces
		piece.marked_faces.clear()
		for saved_face: Variant in faces:
			var face: int = saved_face
			piece.marked_faces.append(face)
		piece.ruined = state.ruined
		pieces.append(piece)
	return pieces
