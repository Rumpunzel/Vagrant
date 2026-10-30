@tool
class_name AdventureLayout
extends Resource

## Where the adventure editor places the pages of one adventure; a file next to the adventure, so moving nodes leaves game data alone

const PLACED_SPECIALS: String = "special"

## Graph positions by page UID (path for pages without one)
@export var positions: Dictionary[String, Vector2] = {}
## Which special node (host, previous location) a link goes to, by the link's key; event views can show several of each
@export var special_links: Dictionary[String, String] = {}

static func get_path_for(adventure: Adventure) -> String:
	return adventure.resource_path.get_basename() + ".layout.tres"

static func load_for(adventure: Adventure) -> AdventureLayout:
	var path: String = get_path_for(adventure)
	var layout: AdventureLayout = load(path) if ResourceLoader.exists(path) else null
	return layout if layout != null else AdventureLayout.new()

## A file's UID (its path without one); a resource inside a file: its ID there, which it keeps when saved
static func get_key(resource: Resource) -> String:
	if resource.resource_path.is_empty() or resource.resource_path.contains("::"): return "::" + resource.resource_scene_unique_id
	var uid: int = ResourceLoader.get_resource_uid(resource.resource_path)
	return ResourceUID.id_to_text(uid) if uid != ResourceUID.INVALID_ID else resource.resource_path

## Map pages placed by hand, reachable or not; event views' keys join several keys
func get_placed_pages() -> Array[AdventurePage]:
	var placed: Array[AdventurePage] = [ ]
	for key: String in positions:
		if not is_location_key(key) or not _exists(key): continue
		var page: AdventurePage = load(key) as AdventurePage
		if page != null: placed.append(page)
	return placed

## A deleted file's UID is unknown, which [method ResourceLoader.exists] reports as an error
static func _exists(key: String) -> bool:
	return (not key.begins_with("uid://") or ResourceUID.has_id(ResourceUID.text_to_id(key))) and ResourceLoader.exists(key)

## A map node's key is one resource's; event view keys join several
static func is_location_key(key: String) -> bool: return key.count("://") == 1

## A node in an event view: [param part] (a resource's key, or a special node's name) in the frame of [param entry] in the view of [param root]
static func get_event_key(root: Resource, entry: Resource, part: String) -> String:
	return "%s/%s/%s" % [get_key(root), get_key(entry), part]

## Special nodes placed from the sidebar: this, then "<kind>/<number>"
static func get_placed_special_prefix(root: Resource, entry: Resource) -> String: return get_event_key(root, entry, "%s/" % PLACED_SPECIALS)

## Placed special nodes exist only through their position, so tidying keeps it
static func is_placed_special(key: String) -> bool: return key.contains("/%s/" % PLACED_SPECIALS)

static func get_switch_key(root: Resource, scenario: Resource) -> String:
	return "%s/switch/%s" % [get_key(root), get_key(scenario)]

func save_for(adventure: Adventure) -> void:
	ResourceSaver.save(self, get_path_for(adventure))
