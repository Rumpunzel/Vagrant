@tool
class_name AdventureDecision
extends Resource

## One way a decision ends: where it leads and what it does, as the decision's properties holding them
class Outcome:
	## Empty for a plain decision's only outcome, which its text names
	var name: String
	var reference_property: StringName
	## Empty: this outcome does nothing
	var consequences_property: StringName

	func _init(outcome_name: String, reference: StringName, effects: StringName) -> void:
		name = outcome_name
		reference_property = reference
		consequences_property = effects

@export_multiline var description: String
## None: goes back [member back_steps] pages
@export var transition: AdventurePageReference
@export_range(1, 5) var back_steps: int = 1
@export var consequences: Array[AdventureConsequence]

@export var _icon: Texture2D
@export var _color: Color = Color.WHITE

## Offered on pages without decisions; it has no transition, so it leads back to the previous page
static func get_turn_back() -> AdventureDecision:
	return load("uid://b4qjxus6rghvc")

## The ways it ends, in order (the game and the adventure editor both go by these); a plain decision has one
func get_outcomes() -> Array[Outcome]: return [Outcome.new("", &"transition", &"consequences")]

## None: goes back
func get_reference(outcome: Outcome) -> AdventurePageReference: return get(outcome.reference_property)

func get_consequences_of(outcome: Outcome) -> Array[AdventureConsequence]:
	var effects: Array[AdventureConsequence] = [ ]
	if not outcome.consequences_property.is_empty(): effects.assign(get(outcome.consequences_property))
	return effects

## Where its outcomes lead, those that lead somewhere
func get_page_references() -> Array[AdventurePageReference]:
	var references: Array[AdventurePageReference] = [ ]
	for outcome: Outcome in get_outcomes():
		var reference: AdventurePageReference = get_reference(outcome)
		if reference != null: references.append(reference)
	return references

func get_icon() -> Texture2D: return _icon
func get_color() -> Color: return _color
