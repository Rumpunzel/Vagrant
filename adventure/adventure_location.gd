@tool
class_name AdventureLocation
extends AdventureEventHost

## A place on the map, in an area: what one walks between, where events happen

@export var area: AdventureArea

func get_area_background() -> Texture2D:
	return area.background if area else null

func get_ambience(story: Story) -> AudioStream:
	var own: AudioStream = super(story)
	if own != null: return own
	return area.ambience if area != null else null

## [event, its source's location] for every nearby event within reach of this location ([member AdventureEvent.nearby_events])
func find_nearby_events() -> Array[Array]:
	var found: Array[Array] = [ ]
	var distances: Dictionary[AdventureLocation, int] = {self: 0}
	var queue: Array[AdventureLocation] = [self]
	while not queue.is_empty():
		var location: AdventureLocation = queue.pop_front()
		if distances[location] >= AdventureEvent.MAX_NEARBY_REACH: continue
		for linked: AdventureLocation in location.get_linked_locations():
			if distances.has(linked): continue
			distances[linked] = distances[location] + 1
			queue.append(linked)
			for source: AdventureEvent in linked.get_listed_events():
				for nearby: AdventureEvent in source.nearby_events:
					if nearby == null: continue
					if (nearby.nearby_reach == 0 or nearby.nearby_stays_in_area) and linked.area != area: continue
					if nearby.nearby_reach > 0 and distances[linked] > nearby.nearby_reach: continue
					if not events.has(nearby) and not found.any(func(pair: Array) -> bool: return pair[0] == nearby): found.append([nearby, linked])
	return found

## The locations this page's decisions lead to by their plain transition: where one walks to, which is what "nearby" means;
## where a fight or save ends doesn't count (the map draws those as links too)
func get_linked_locations() -> Array[AdventureLocation]:
	var linked: Array[AdventureLocation] = [ ]
	for decision: AdventureDecision in decisions:
		var page: AdventurePage = decision.transition.load_page() if decision != null and decision.transition != null else null
		if page is AdventureLocation and not linked.has(page): linked.append(page as AdventureLocation)
	return linked

func _get_own_title() -> String:
	return "%s — %s" % [area.name, title] if area != null else title

func _get_nearby_events(story: Story) -> Array[AdventureEvent]: return story.get_nearby_events(self)
