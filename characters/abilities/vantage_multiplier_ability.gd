@tool
class_name VantageMultiplierAbility
extends Ability

@export_range(1, 4) var multiplier: int = 2

func modify_vantage(vantage: int) -> int: return vantage * multiplier
