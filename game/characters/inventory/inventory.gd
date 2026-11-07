@tool
class_name Inventory
extends PanelContainer

## What a character carries, grouped in columns side by side (wrapping where the panel is narrow, scrolling where it is low): weapons, shields and armour, each piece with its icon, its die (or what it blocks), the attribute it is
## wielded with and its faces, the marked ones struck out; then items in a number. Of a profile (fresh pieces) or of a character (marks, gains
## and losses as they happen). Each row's tooltip tells the item's description and what it does.

const ICON_SIZE: int = 24
## At least about a heading and a row high; it takes what room there is beyond that up to its columns' height, and scrolls in less, so it never
## pushes what comes below it off the screen
const HEIGHT_MIN: float = 52.0
## A group's column is at least this wide
const COLUMN_WIDTH: float = 160.0
const SMALL_ICON_SIZE: int = 16
const RUINED: Color = Color(1, 1, 1, 0.4)
## The failure red, light enough to read on dark panels
const MARKED: Color = Color("e57373")
## Stand in for a piece's or item's own icon when it has none, by group
const GROUP_ICONS: Dictionary[String, Texture2D] = {
	"Weapons": preload("uid://boyixi5guyonr"),  # broadsword.svg
	"Shields": preload("uid://cyxyw6jc62i5h"),  # round-shield.svg
	"Armour": preload("uid://ccbnrcl8pu3cg"),  # leather-vest.svg
	"Items": preload("uid://b4a43twbi6cri"),  # swap-bag.svg
}

@export var _character_profile: CharacterProfile:
	set(new_character_profile):
		assert(new_character_profile)
		_character_profile = new_character_profile

@export_group("Configuration")
## The groups' columns
@export var _rows: HFlowContainer

var _character: Character
var _watched: Array[Equipment] = []
## Each row as plain text ("Sword (d10) — marked 7"), for tests and logs
var _entries: Array[String] = []

func setup(character_profile: CharacterProfile) -> void:
	_character_profile = character_profile
	_set_character(null)
	_show(Weapon.carry(character_profile.weapons), Shield.carry(character_profile.shields), Armor.carry(character_profile.armor), character_profile.items)

func show_character(character: Character) -> void:
	assert(character)
	_character_profile = character.character_profile
	_set_character(character)
	_refresh()

func get_entries() -> Array[String]: return _entries.duplicate()

## A piece's faces (a die's, or the results armour blocks), the marked ones struck out in red; then "ruined" or "dropped" if so
static func describe_faces(piece: Equipment) -> String:
	var faces: Array[String] = []
	for face: int in piece.get_markable_faces():
		faces.append("[color=#%s][s]%d[/s][/color]" % [MARKED.to_html(), face] if piece.is_marked(face) else "%d" % face)
	var description: String = " ".join(faces)
	if not piece.is_usable(): description = "[color=gray]%s — %s[/color]" % [description, "dropped" if piece.dropped and not piece.ruined else "ruined"]
	return description

func _refresh() -> void:
	_show(_character.weapons, _character.shields, _character.armor, _character.items)

## Marks made in a fight, and what is gained or lost, show up right away
func _set_character(character: Character) -> void:
	if _character != null and _character.carried_changed.is_connected(_on_carried_changed): _character.carried_changed.disconnect(_on_carried_changed)
	_character = character
	_watch_gear()
	if _character != null: _character.carried_changed.connect(_on_carried_changed)

## The pieces carried now, whose marks show up right away
func _watch_gear() -> void:
	for equipment: Equipment in _watched: if equipment.changed.is_connected(_refresh): equipment.changed.disconnect(_refresh)
	_watched = []
	if _character != null: _watched = _character.get_gear()
	for equipment: Equipment in _watched: equipment.changed.connect(_refresh)

func _on_carried_changed() -> void:
	_watch_gear()
	_refresh()

func _show(weapons: Array[Weapon], shields: Array[Shield], armor: Array[Armor], items: Dictionary[ItemProfile, int]) -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_entries.clear()
	for weapon: Weapon in weapons: _add_piece("Weapons", weapon, _describe_die(weapon.get_die_type(), weapon.get_wield_attribute()), "%s (%s)" % [weapon.get_equipment_name(), weapon.get_die_type()])
	for shield: Shield in shields: _add_piece("Shields", shield, _describe_die(shield.get_die_type(), shield.get_wield_attribute()), "%s (%s)" % [shield.get_equipment_name(), shield.get_die_type()])
	for piece: Armor in armor: _add_piece("Armour", piece, _describe_armor(piece), _name_armor(piece))
	for item: ItemProfile in items: _add_item(item, items[item])
	_fit_height.call_deferred()

## Once the columns are laid out
func _fit_height() -> void:
	var scroll: Control = _rows.get_parent() as Control
	scroll.custom_minimum_size.y = minf(_rows.get_combined_minimum_size().y, HEIGHT_MIN)

## The column of [param group], made with its heading when its first row comes
func _get_column(group: String) -> VBoxContainer:
	for column: Node in _rows.get_children(): if column.name == group: return column as VBoxContainer
	var column: VBoxContainer = VBoxContainer.new()
	column.name = group
	column.custom_minimum_size.x = COLUMN_WIDTH
	column.add_theme_constant_override(&"separation", 2)
	var heading: Label = Label.new()
	heading.text = group
	heading.modulate = Color(1, 1, 1, 0.6)
	column.add_child(heading)
	_rows.add_child(column)
	return column

## Its icon, then its name and [param details] on one line and its faces below; faded once ruined. [param entry]: the row as plain text
func _add_piece(group: String, piece: Equipment, details: String, entry: String) -> void:
	if piece.ruined: entry += " — ruined"
	elif not piece.marked_faces.is_empty(): entry += " — marked %s" % ", ".join(piece.marked_faces.map(func(face: int) -> String: return "%d" % face))
	_entries.append(entry)
	var row: HBoxContainer = _add_row(piece.get_item_profile(), group, "[b]%s[/b]  %s\n%s" % [piece.get_equipment_name(), details, describe_faces(piece)], _describe_rules(piece))
	if piece.ruined: row.modulate = RUINED

func _add_item(item: ItemProfile, count: int) -> void:
	var text: String = item.name if count == 1 else "%s ×%d" % [item.name, count]
	_entries.append(text)
	_add_row(item, "Items", "[b]%s[/b]" % text if count == 1 else "[b]%s[/b] ×%d" % [item.name, count], item.description)

func _add_row(item: ItemProfile, group: String, text: String, tooltip: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.tooltip_text = tooltip
	var icon: TextureRect = TextureRect.new()
	icon.texture = item.icon if item.icon != null else GROUP_ICONS[group]
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	# One line each, no wrapping: the column is as wide as its widest row
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	row.add_child(label)
	_get_column(group).add_child(row)
	return row

## "[d10 icon] d10 [Guts icon]": the die rolled, and the attribute it must stay within, in its colour
static func _describe_die(die_type: DieType, attribute: CharacterAttribute) -> String:
	var die: String = "%s %s" % [_icon(die_type.icon, Color.WHITE), die_type]
	if attribute == null: return die
	return "%s  %s" % [die, _icon(attribute.icon, attribute.color) if attribute.icon != null else "[color=#%s]%s[/color]" % [attribute.color.to_html(), attribute.descriptor]]

static func _describe_armor(piece: Armor) -> String:
	return "−%d damage" % piece.armor_profile.damage_reduction if piece.armor_profile.damage_reduction > 0 else ""

## "Helmet (blocks 5, 10)", "Gambeson (−1 damage)"
static func _name_armor(piece: Armor) -> String:
	var details: Array[String] = []
	if not piece.armor_profile.blocked_results.is_empty(): details.append("blocks %s" % ", ".join(piece.armor_profile.blocked_results.map(func(result: int) -> String: return "%d" % result)))
	if piece.armor_profile.damage_reduction > 0: details.append("−%d damage" % piece.armor_profile.damage_reduction)
	return "%s (%s)" % [piece.get_equipment_name(), "; ".join(details)] if not details.is_empty() else piece.get_equipment_name()

## Its description, then what it does in a fight and what its marks mean
static func _describe_rules(piece: Equipment) -> String:
	var lines: Array[String] = []
	var description: String = piece.get_item_profile().description
	if not description.is_empty(): lines.append(description)
	var weapon: Weapon = piece as Weapon
	var shield: Shield = piece as Shield
	var armor: Armor = piece as Armor
	if weapon != null:
		lines.append("Strikes with a %s. Above your %s it must be forced, which marks it." % [weapon.get_die_type(), weapon.get_wield_attribute().descriptor])
	elif shield != null:
		lines.append("Raised, takes its %s's result off a blow. Above your %s it must be forced." % [shield.get_die_type(), shield.get_wield_attribute().descriptor])
	elif armor != null:
		if not armor.armor_profile.blocked_results.is_empty(): lines.append("Blocks a weapon die showing %s; a blocked result gets marked." % ", ".join(armor.armor_profile.blocked_results.map(func(result: int) -> String: return "%d" % result)))
		if armor.armor_profile.damage_reduction > 0: lines.append("Takes %d off all damage." % armor.armor_profile.damage_reduction)
	lines.append("Marking a marked face marks the next higher one; with none left, it is ruined.")
	return "\n".join(lines)

static func _icon(texture: Texture2D, color: Color) -> String:
	if texture == null or texture.resource_path.is_empty(): return ""
	return "[img=%dx%d color=#%s]%s[/img]" % [SMALL_ICON_SIZE, SMALL_ICON_SIZE, color.to_html(), texture.resource_path]
