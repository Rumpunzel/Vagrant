class_name AdventureSaveDecision
extends AdventureDiceDecision

@export_multiline var details: String
@export var attribute: CharacterAttribute
@export_range(0, 12) var difficulty: int
@export var failure_transition: AdventurePageReference

func to_dice_request(protagonist: Character) -> SaveRequest:
	return SaveRequest.new(protagonist, attribute, self)

func get_icon() -> Texture2D:
	var custom_icon: Texture2D = super.get_icon()
	if custom_icon: return custom_icon
	return attribute.icon

func get_color() -> Color:
	var custom_color: Color = super.get_color()
	if custom_color != Color.WHITE: return custom_color
	return attribute.color
