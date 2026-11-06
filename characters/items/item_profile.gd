class_name ItemProfile
extends Resource

## Something carried: a plain item, carried in a number, or gear (weapons, armour, shields), carried as pieces that get marked.
## Story items have no rules of their own.

@export_placeholder("Name") var name: String
@export var icon: Texture2D
@export_multiline var description: String

## Weapons, armour and shields: carried as pieces, each with its own marks
func is_gear() -> bool: return false

static func create_item(new_name: String, new_icon: Texture2D = null, new_description: String = "") -> ItemProfile:
	var item_profile: ItemProfile = ItemProfile.new()
	item_profile.name = new_name
	item_profile.icon = new_icon
	item_profile.description = new_description
	return item_profile

## "Sword", "2 Rations" ([param several] with the count and the name for more than one); "?" for none
static func describe_amount(item: ItemProfile, count: int, several: String = "%d %s") -> String:
	if item == null: return "?"
	return item.name if count == 1 else several % [count, item.name]
