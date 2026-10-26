@tool
@abstract
class_name AdventureConsequence
extends Resource

@abstract func resolve(story: Story, margin: int) -> void
## Short text for the adventure editor ("Kill Lurker")
@abstract func describe() -> String
