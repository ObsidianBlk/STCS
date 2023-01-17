@tool
extends Node


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal database_added(db_name)
signal database_removed(db_name)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CDB_PATH : Dictionary = {
	&"core": "res://data/core/cdb/",
	#&"exp1": "res://data/exp1/cdb/",  # Example of an "expansion" data folder.
	&"user": ["user://data/cdb/"]
}


func create_blank_component_database():
	return preload("res://addons/STCSDataControl/resources/ComponentDB.gd").new()

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _dbcollection : Dictionary = {}
var _active_path_id : StringName = &"core"

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _SaveDB(sha : StringName) -> int:
	var path_id : StringName = _dbcollection[sha][&"path_id"]
	var path : String = CDB_PATH[path_id]
	if not DirAccess.dir_exists_absolute(path):
		var res : int = DirAccess.make_dir_recursive_absolute(path)
		if res != OK:
			return res
	var file_path : String = "%s%s"%[path, _dbcollection[sha][&"filename"]]
	return _dbcollection[sha][&"db"].save(file_path)


func _RemoveDB(sha : StringName) -> int:
	var path_id : StringName = _dbcollection[sha][&"path_id"]
	var path : String = CDB_PATH[path_id]
	var file_path : String = "%s%s"%[path, _dbcollection[sha][&"filename"]]
	var res : int = DirAccess.remove_absolute(file_path)
	if res == OK:
		var db : ComponentDB = _dbcollection[sha][&"db"]
		_dbcollection.erase(sha)
		database_removed.emit(db.name)
	return res

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_active_path_id(path_id : StringName) -> void:
	if path_id in CDB_PATH and path_id != &"user":
		_active_path_id = path_id

func get_active_path_id() -> StringName:
	return _active_path_id

func load_database_resources() -> int:
	for path_id in CDB_PATH.keys():
		var base_path : String = CDB_PATH[path_id]
		var dir : DirAccess = DirAccess.open(base_path)
		dir.list_dir_begin()
		var filename : String = dir.get_next()
		while filename != "":
			if not dir.current_is_dir():
				if filename.begins_with("CDB_") and filename.ends_with(".res"):
					var db = ResourceLoader.load("%s%s"%[base_path, filename])
					if db is ComponentDB:
						add_database_resource(db, false)
			filename = dir.get_next()
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
			_dbcollection.erase(sha)
			return res
	database_added.emit(db.name)
	return OK

func remove_database(db_name : String) -> int:
	return remove_database_by_key(db_name.sha256_text())

func remove_database_by_key(key : StringName) -> int:
	if key in _dbcollection:
		if _dbcollection[key][&"path_id"] != &"user":
			if not Engine.is_editor_hint():
				return ERR_LOCKED
		return _RemoveDB(key)
	return OK

func create_database(db_name : String, auto_save_db : bool = true) -> int:
	var db : ComponentDB = CCDB.create_black_component_database()
	db.name = db_name
	return add_database_resource(db, auto_save_db)

func get_database(db_name : String) -> ComponentDB:
	return get_database_by_key(db_name.sha256_text())

func get_database_by_key(key : StringName) -> ComponentDB:
	if key in _dbcollection:
		return _dbcollection[key][&"db"]
	return null

func get_database_list() -> Array:
	var list : Array = []
	for key in _dbcollection.keys():
		list.append({
			&"key": key,
			&"name": _dbcollection[key][&"db"].name
		})
	return list


