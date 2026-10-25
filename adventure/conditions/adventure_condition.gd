@tool
@abstract
class_name AdventureCondition
extends Resource

## [param page] is the page (or event) whose prerequisite this is
@abstract func is_true(story: Story, page: AdventurePage) -> bool

## Short text for the adventure editor ("Lurker can fight"); empty: says nothing worth showing
func describe() -> String: return ""
