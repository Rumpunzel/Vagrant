class_name ExchangeSteps
extends Resource

## The steps of an exchange. Only the resolution is authored here; the phases around it are fixed by the rules:
## the player commits first, then the roll is told, then the [member resolution] applies what the exchange did,
## and its aftermath (the incapacitation saves) follows once the breath dice and injuries are taken.

## Applied and shown in this order
@export var resolution: Array[ResolutionStep] = []

## Every step in the order an exchange goes through them
func get_steps() -> Array[ExchangeStep]:
	var steps: Array[ExchangeStep] = [_create(CommitStep, ExchangeStep.ExchangeSide.FIRST)]
	# Whoever started the fight is told first; for now that is always the monster
	steps.append_array([_create(DiceStep, ExchangeStep.ExchangeSide.SECOND), _create(DiceStep, ExchangeStep.ExchangeSide.FIRST), TieStep.new()])
	steps.append_array(resolution)
	steps.append_array([_create(IncapacitationStep, ExchangeStep.ExchangeSide.SECOND), _create(IncapacitationStep, ExchangeStep.ExchangeSide.FIRST)])
	return steps

static func _create(step_script: GDScript, side: ExchangeStep.ExchangeSide) -> ExchangeStep:
	var step: ExchangeStep = step_script.new()
	step.side = side
	return step
