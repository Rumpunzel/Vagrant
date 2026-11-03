class_name ResourceId
extends RefCounted

## Names a resource so it can be found again in another run (saves, logs, "Play from here"): its file's UID (the path if the file has none),
## plus, for a resource stored inside a file, its ID there: "uid://…::Resource_x". Resources made at runtime have no name.

const SEPARATOR: String = "::"

## Empty for a resource made at runtime (no file)
static func of(resource: Resource) -> String:
	if resource == null or resource.resource_path.is_empty(): return ""
	var file: String = resource.resource_path.get_slice(SEPARATOR, 0)
	var uid: int = ResourceLoader.get_resource_uid(file)
	var file_id: String = ResourceUID.id_to_text(uid) if uid != ResourceUID.INVALID_ID else file
	if not resource.resource_path.contains(SEPARATOR): return file_id
	return file_id + SEPARATOR + resource.resource_scene_unique_id

## The resource [param id] names, or null if its file or its place in there is gone
static func find(id: String) -> Resource:
	if id.is_empty(): return null
	var root: Resource = Files.load_existing(id.get_slice(SEPARATOR, 0))
	if root == null or not id.contains(SEPARATOR): return root
	return _find_inside(root, root.resource_path, id.get_slice(SEPARATOR, 1), {})

## Godot can't load a resource stored inside a file by itself: walks what the file stores, not into other files
static func _find_inside(value: Variant, file: String, inner_id: String, seen: Dictionary[Resource, bool]) -> Resource:
	if value is Array:
		for item: Variant in value as Array:
			var found: Resource = _find_inside(item, file, inner_id, seen)
			if found != null: return found
	elif value is Dictionary:
		var dictionary: Dictionary = value
		for key: Variant in dictionary:
			var found: Resource = _find_inside(key, file, inner_id, seen)
			if found == null: found = _find_inside(dictionary[key], file, inner_id, seen)
			if found != null: return found
	elif value is Resource:
		var resource: Resource = value
		if seen.has(resource): return null
		seen[resource] = true
		if resource.resource_path != file and not resource.resource_path.begins_with(file + SEPARATOR): return null
		if resource.resource_path != file and resource.resource_scene_unique_id == inner_id: return resource
		for property: Dictionary in resource.get_property_list():
			if not (property["usage"] as int) & PROPERTY_USAGE_STORAGE: continue
			var found: Resource = _find_inside(resource.get(property["name"] as String), file, inner_id, seen)
			if found != null: return found
	return null

static func of_each(resources: Array) -> Array[String]:
	var ids: Array[String] = []
	for resource: Resource in resources: ids.append(of(resource))
	return ids

## Into a typed array with [method Array.assign]
static func find_each(ids: Array) -> Array[Resource]:
	var resources: Array[Resource] = []
	for id: String in ids: resources.append(find(id))
	return resources
