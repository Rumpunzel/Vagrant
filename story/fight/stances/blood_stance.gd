class_name BloodStance
extends FightStance

func modify_damage_taken(damage: int, vantage: int) -> int: return damage - vantage
