class_name BloodStance
extends FightStance

func modify_damage_taken(damage: int, margin: int) -> int: return damage - margin
