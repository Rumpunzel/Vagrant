class_name TestMonsters
extends RefCounted

## Monsters owned by the tests, so balancing the game's monsters does not break them.

## Guts 5, Blood 7, Nerves 7, three d8 breath dice, a d8 knife, threatens with Guts
static func cutthroat() -> MonsterProfile:
	var profile: MonsterProfile = MonsterProfile.new()
	profile.name = "Cutthroat"
	profile.attribute_scores = {Rules.STRENGTH: 5, Rules.AGILITY: 7, Rules.INTELLIGENCE: 7} as Dictionary[CharacterAttribute, int]
	profile.weapons = [WeaponProfile.create("Knife", Rules.d8)] as Array[WeaponProfile]
	profile.attack = GutsAttack.new()
	return profile

## Like the cutthroat, but threatens with Nerves to impair [param target]
static func unnerver(target: CharacterAttribute = Rules.STRENGTH) -> MonsterProfile:
	var profile: MonsterProfile = TestMonsters.cutthroat()
	profile.name = "Unnerver"
	var attack: NervesAttack = NervesAttack.new()
	attack.target = target
	profile.attack = attack
	return profile

## Guts, Blood and Nerves 7, three d8 breath dice, natural weapons
static func brute() -> MonsterProfile:
	var profile: MonsterProfile = MonsterProfile.new()
	profile.name = "Brute"
	profile.attack = GutsAttack.new()
	return profile
