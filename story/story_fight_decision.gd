class_name StoryFightDecision
extends StoryDiceDecision

func get_adventure_decision() -> AdventureFightDecision: return _adventure_decision
func get_dice_request() -> FightRequest: return dice_request
func get_dice_result() -> FightResult: return dice_result

func get_transition() -> AdventurePage: return null

func get_consequences() -> Array[StoryConsequence]:
	var story_consequences: Array[StoryConsequence] = []
	story_consequences.assign(get_adventure_decision().consequences.map(StoryConsequence.from_adventure_consequence))
	return story_consequences

func get_icon() -> Texture2D:
	var custom_icon: Texture2D = get_adventure_decision().get_icon()
	if custom_icon: return custom_icon
	return get_dice_request().attribute.fight_icon

func get_icon_color() -> Color:
	var custom_color: Color = get_adventure_decision().get_color()
	if custom_color != Color.WHITE: return custom_color
	return get_dice_request().attribute.color
