@tool
@abstract
class_name AdventureConsequence
extends Resource

@abstract func resolve(story: Story, margin: int) -> void
## Whether resolving it shows something right away (an injury on the character), which the story pauses for before going on; most change
## only what comes later
func is_shown() -> bool: return false
## Short text for the adventure editor ("Kill Lurker")
@abstract func describe() -> String
