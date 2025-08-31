class_name Files

static func list_all_directories(
	directory_path: String,
	search_recursively: bool = true,
	filter: Callable = func(_directory_name: String) -> bool: return true,
) -> Array[String]:
	var directories: Array[String] = []
	var directory: DirAccess = DirAccess.open(directory_path)
	if not directory:
		printerr("Could not open directory_path at path: %s" % directory_path)
		return []
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if directory.current_is_dir():
			var file_path: String = directory_path.path_join(file_name)
			if filter.call(file_name): directories.append(file_path)
			if search_recursively: directories.append_array(list_all_directories(file_path, search_recursively, filter))
		file_name = directory.get_next()
	return directories

static func list_all_files(
	directory_path: String,
	search_recursively: bool = true,
	filter: Callable = func(_file_name: String) -> bool: return true,
) -> Array[String]:
	var files: Array[String] = []
	var directory: DirAccess = DirAccess.open(directory_path)
	if not directory:
		printerr("Could not open directory_path at path: %s" % directory_path)
		return []
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		var file_path: String = directory_path.path_join(file_name)
		if directory.current_is_dir():
			if search_recursively: files.append_array(list_all_files(file_path))
		elif filter.call(file_name): files.append(file_path)
		file_name = directory.get_next()
	return files
