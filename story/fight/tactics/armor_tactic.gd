@abstract
class_name ArmorTactic
extends Resource

## How a defender decides which piece of armour takes a blocked blow

## One of [param options] (see [method ArmorPick.get_options]), never empty
@abstract func pick(options: Array[ArmorPick]) -> ArmorPick
