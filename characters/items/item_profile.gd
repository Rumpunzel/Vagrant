class_name ItemProfile
extends Resource

## A plain item without rules (yet), carried in a given number

@export_placeholder("Name") var name: String
@export var icon: Texture2D
@export_multiline var description: String

static func create(new_name: String, new_icon: Texture2D = null, new_description: String = "") -> ItemProfile:
	var item_profile: ItemProfile = ItemProfile.new()
	item_profile.name = new_name
	item_profile.icon = new_icon
	item_profile.description = new_description
	return item_profile
