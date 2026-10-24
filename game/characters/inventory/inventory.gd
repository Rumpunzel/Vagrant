@tool
class_name Inventory
extends PanelContainer

## Lists weapons, armour, shields and items: of a profile (fresh) or of a character (with marks).

@export var _character_profile: CharacterProfile:
	set(new_character_profile):
		assert(new_character_profile)
		_character_profile = new_character_profile

@export_group("Configuration")
@export var _list: ItemList

var _character: Character

func setup(character_profile: CharacterProfile) -> void:
	_character_profile = character_profile
	_set_character(null)
	_list.clear()
	for weapon: Weapon in Weapon.carry(character_profile.weapons): _add_equipment(weapon, "%s (%s)" % [weapon.get_equipment_name(), weapon.get_die_type()])
	for piece: Armor in Armor.carry(character_profile.armor): _add_equipment(piece, _describe_armor(piece))
	for shield: Shield in Shield.carry(character_profile.shields): _add_equipment(shield, "%s (%s)" % [shield.get_equipment_name(), shield.get_die_type()])
	_add_items(character_profile.items)

func show_character(character: Character) -> void:
	assert(character)
	_character_profile = character.character_profile
	_set_character(character)
	_refresh()

func get_entries() -> Array[String]:
	var entries: Array[String] = []
	for index: int in _list.item_count: entries.append(_list.get_item_text(index))
	return entries

func _refresh() -> void:
	_list.clear()
	for weapon: Weapon in _character.weapons: _add_equipment(weapon, "%s (%s)" % [weapon.get_equipment_name(), weapon.get_die_type()])
	for piece: Armor in _character.armor: _add_equipment(piece, _describe_armor(piece))
	for shield: Shield in _character.shields: _add_equipment(shield, "%s (%s)" % [shield.get_equipment_name(), shield.get_die_type()])
	_add_items(_character.items)

## Marks made in a fight show up right away
func _set_character(character: Character) -> void:
	if _character:
		for equipment: Equipment in _get_equipment(_character): if equipment.changed.is_connected(_refresh): equipment.changed.disconnect(_refresh)
	_character = character
	if not _character: return
	for equipment: Equipment in _get_equipment(_character): equipment.changed.connect(_refresh)

func _add_equipment(equipment: Equipment, text: String) -> void:
	if equipment.ruined: text += " — ruined"
	elif not equipment.marked_faces.is_empty(): text += " — marked %s" % ", ".join(equipment.marked_faces.map(func(face: int) -> String: return "%d" % face))
	_list.add_item(text)

func _add_items(items: Dictionary[ItemProfile, int]) -> void:
	for item: ItemProfile in items:
		var text: String = item.name if items[item] == 1 else "%s ×%d" % [item.name, items[item]]
		_list.add_item(text, item.icon)

static func _describe_armor(piece: Armor) -> String:
	var details: Array[String] = []
	if not piece.armor_profile.blocked_results.is_empty(): details.append("blocks %s" % ", ".join(piece.armor_profile.blocked_results.map(func(result: int) -> String: return "%d" % result)))
	if piece.armor_profile.damage_reduction > 0: details.append("−%d damage" % piece.armor_profile.damage_reduction)
	return "%s (%s)" % [piece.get_equipment_name(), "; ".join(details)] if not details.is_empty() else piece.get_equipment_name()

static func _get_equipment(character: Character) -> Array[Equipment]:
	var equipment: Array[Equipment] = []
	equipment.append_array(character.weapons)
	equipment.append_array(character.armor)
	equipment.append_array(character.shields)
	return equipment
