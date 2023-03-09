@tool
extends Node


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal database_saved(db_key)
signal database_added(db_key, db_name)
signal database_dropped(db_key, db_name)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CDB_PATH : Dictionary = {
	&"core": "res://data/core/cdb/",
	#&"exp1": "res://data/exp1/cdb/",  # Example of an "expansion" data folder.
	&"user": "user://data/cdb/"
}

const COMP_SEARCH_OPTIONS_SCHEMA : Dictionary = {
	&"type":{&"req":false, &"type":TYPE_STRING_NAME},
	&"size":{&"req":false, &"type":TYPE_INT, &"min":0},
	&"attribs":{&"req":false, &"type":TYPE_ARRAY, &"item":{&"type":TYPE_STRING_NAME}}
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _dbcollection : Dictionary = {}
var _active_path_id : StringName = &"core"

var _load_resources_requested : bool = false

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _SaveDB(sha : StringName) -> int:
	var path_id : StringName = _dbcollection[sha][&"path_id"]
	if path_id == &"user" or Engine.is_editor_hint():
		var path : String = CDB_PATH[path_id]
		if not DirAccess.dir_exists_absolute(path):
			var res : int = DirAccess.make_dir_recursive_absolute(path)
			if res != OK:
				printerr("[", res, "]: Path creation failed.")
				return res
		var file_path : String = "%s%s"%[path, _dbcollection[sha][&"filename"]]
		return _dbcollection[sha][&"db"].save(file_path)
	printerr("Component database is locked for editing and cannot be saved.")
	return ERR_LOCKED


func _EraseDB(sha : StringName) -> int:
	var path_id : StringName = _dbcollection[sha][&"path_id"]
	var path : String = CDB_PATH[path_id]
	var file_path : String = "%s%s"%[path, _dbcollection[sha][&"filename"]]
	var res : int = DirAccess.remove_absolute(file_path)
	if res == OK:
		var db : ComponentDB = _dbcollection[sha][&"db"]
		_dbcollection.erase(sha)
		database_dropped.emit(sha, db.name)
		#database_removed.emit(sha, db.name)
	return res

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear(save_dirty : bool = false) -> void:
	for key in _dbcollection:
		if save_dirty == true and _dbcollection[key][&"db"].is_dirty():
			var res : int = _SaveDB(key)
			if res == OK:
				database_saved.emit(key)

func set_active_path_id(path_id : StringName) -> void:
	if path_id in CDB_PATH and path_id != &"user":
		_active_path_id = path_id

func get_active_path_id() -> StringName:
	return _active_path_id

func load_database_resources() -> int:
	for path_id in CDB_PATH.keys():
		var base_path : String = CDB_PATH[path_id]
		var dir : DirAccess = DirAccess.open(base_path)
		if dir != null:
			dir.list_dir_begin()
			var filename : String = dir.get_next()
			while filename != "":
				if not dir.current_is_dir():
					if filename.begins_with("CDB_") and filename.ends_with(".res"):
						var db = ResourceLoader.load("%s%s"%[base_path, filename])
						if db is ComponentDB:
							var _res : int = add_database_resource(db, false)
				filename = dir.get_next()
			dir.list_dir_end()
	return OK

func add_database_resource(db : ComponentDB, auto_save_db : bool = true) -> int:
	if db.name.strip_edges() == "":
		return ERR_UNCONFIGURED
	var sha : StringName = db.name.sha256_text()
	if sha in _dbcollection:
		return ERR_ALREADY_IN_USE
	_dbcollection[sha] = {
		&"db": db,
		&"filename": "CDB_%s.res"%[sha],
		&"path_id": _active_path_id if Engine.is_editor_hint() else &"user"
	}
	if auto_save_db:
		var res : int = _SaveDB(sha)
		if res != OK:
			printerr("[", res, "]: Failed to save component database.")
			_dbcollection.erase(sha)
			return res
		database_saved.emit(sha)
	database_added.emit(sha, db.name)
	return OK

func erase_database(db_name : String) -> int:
	return erase_database_by_key(db_name.sha256_text())

func erase_database_by_key(key : StringName) -> int:
	if key in _dbcollection:
		if _dbcollection[key][&"path_id"] != &"user":
			if not Engine.is_editor_hint():
				return ERR_LOCKED
		return _EraseDB(key)
	return OK

func drop_database(db_name : String) -> int:
	return drop_database(db_name.sha256_text())

func drop_database_by_key(key : StringName) -> int:
	if not key in _dbcollection:
		return ERR_DOES_NOT_EXIST
	var db : ComponentDB = _dbcollection[key][&"db"]
	_dbcollection.erase(key)
	database_dropped.emit(key, db.name)
	return OK

func create_database(db_name : String, auto_save_db : bool = true) -> int:
	var db : ComponentDB = ComponentDB.new() #CCDB.create_blank_component_database()
	db.name = db_name
	return add_database_resource(db, auto_save_db)

func save_database(db_name : String) -> int:
	return save_database_by_key(db_name.sha256_text())

func save_database_by_key(key : StringName) -> int:
	if not key in _dbcollection:
		return ERR_DOES_NOT_EXIST
	if _dbcollection[key][&"db"].is_dirty():
		var res : int = _SaveDB(key)
		if res == OK:
			database_saved.emit(key)
	return OK

func has_database(db_name : String) -> bool:
	return has_database_by_key(db_name.sha256_text())

func has_database_by_key(key : StringName) -> bool:
	return (key in _dbcollection)

func get_database_key_from_name(db_name : String) -> StringName:
	var sha : StringName = db_name.sha256_text()
	if sha in _dbcollection:
		return sha
	return &""

func get_database_name_from_key(key : StringName) -> String:
	if key in _dbcollection:
		return _dbcollection[key][&"db"].name
	return ""

func get_database(db_name : String) -> ComponentDB:
	return get_database_by_key(db_name.sha256_text())

func get_database_by_key(key : StringName) -> ComponentDB:
	if key in _dbcollection:
		return _dbcollection[key][&"db"]
	return null

func get_database_path_id(db_name : String) -> StringName:
	return get_database_path_id_by_key(db_name.sha256_text())

func get_database_path_id_by_key(key : StringName) -> StringName:
	if key in _dbcollection:
		return _dbcollection[key][&"path_id"]
	return &""

func get_component(db_name : StringName, uuid : StringName) -> Dictionary:
	var db : ComponentDB = get_database(db_name)
	if db != null:
		return db.get_component(uuid)
	return {}

func get_database_list(limit_to_path_id : StringName = &"") -> Array:
	var list : Array = []
	for key in _dbcollection.keys():
		if limit_to_path_id == &"" or _dbcollection[key][&"path_id"] == limit_to_path_id:
			list.append({
				&"key": key,
				&"name": _dbcollection[key][&"db"].name
			})
	return list

func get_component_list(options : Dictionary = {}) -> Array:
	var arr : Array = []
	if DSV.verify(options, COMP_SEARCH_OPTIONS_SCHEMA) == OK:
		for key in _dbcollection.keys():
			var cdb : ComponentDB = _dbcollection[key][&"db"]
			for item in cdb.get_component_list():
				item[&"db_name"] = cdb.name
				if not options.is_empty():
					if &"type" in options:
						if not item[&"type"] == options[&"type"]:
							continue
					if &"size" in options:
						if not (item[&"size_range"].x <= options[&"size"] and item[&"size_range"].y >= options[&"size"]):
							continue
					if &"attribs" in options:
						if not cdb.component_has_attributes(item[&"uuid"], options[&"attribs"]):
							continue
				arr.append(item)
	return arr

func is_component_in_database(db_name : String, uuid : StringName) -> bool:
	return is_component_in_database_by_key(db_name.sha256_text(), uuid)

func is_component_in_database_by_key(key : StringName, uuid : StringName) -> bool:
	var db : ComponentDB = get_database_by_key(key)
	if db:
		return db.has_component(uuid)
	return false
