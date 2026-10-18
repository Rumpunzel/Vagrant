class_name StoryFightDecision
extends StoryDiceDecision

## One option of a fight exchange: fight back or flee. Each exchange page gets a fresh pair.

var fight: Fight
var fleeing: bool

func _init(for_fight: Fight, is_fleeing: bool) -> void:
	assert(for_fight)
	fight = for_fight
	fleeing = is_fleeing
	super(fight.decision, fight.protagonist)

func get_adventure_decision() -> AdventureFightDecision: return _adventure_decision
func get_dice_request() -> FightRequest: return dice_request
func get_dice_result() -> FightResult: return dice_result

func get_description() -> String:
	return get_adventure_decision().flee_description if fleeing else super()

## Only once the fight is over; while it goes on, Story shows the next exchange
func get_transition() -> AdventurePage:
	return null if fight.is_ongoing() else fight.get_transition()

func get_consequences() -> Array[StoryConsequence]:
	var story_consequences: Array[StoryConsequence] = []
	if not fight.is_ongoing(): story_consequences.assign(fight.get_consequences().map(StoryConsequence.from_adventure_consequence))
	return story_consequences

func get_icon() -> Texture2D:
	var custom_icon: Texture2D = get_adventure_decision().get_icon()
	if custom_icon and not fleeing: return custom_icon
	return get_dice_request().attribute.icon if fleeing else get_dice_request().attribute.fight_icon

func get_icon_color() -> Color:
	var custom_color: Color = get_adventure_decision().get_color()
	if custom_color != Color.WHITE and not fleeing: return custom_color
	return get_dice_request().attribute.color

func _setup(_protagonist: Character) -> void:
	dice_request = fight.create_request(fleeing)
