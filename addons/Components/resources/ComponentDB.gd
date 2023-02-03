@tool
extends Resource
class_name ComponentDB


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal component_added(uuid)
signal component_removed(uuid)
signal saved()
signal dirtied()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _name : String = ""
var _db : Dictionary = {}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _types : Dictionary = {}
var _tags : Dictionary = {}


var _dirty : bool = false
var _locked : bool = false

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _get(property : StringName):
	match property:
		&"name":
			return _name
		&"db":
			return _db
	return null

func _set(property : StringName, value) -> bool:
	var success : bool = true
	
	match property:
		&"name":
			if typeof(value) == TYPE_STRING:
				_name = value
			else : success = false
		&"db":
			if typeof(value) == TYPE_DICTIONARY:
				set_database_dictionary(value, true)
			else : success = false
		_:
			success = false
	
	return success

func _get_property_list() -> Array:
	var arr : Array = [
		{
			name=&"name",
			type=TYPE_STRING,
			usage=PROPERTY_USAGE_DEFAULT
		},
		{
			name=&"db",
			type=TYPE_DICTIONARY,
			usage=PROPERTY_USAGE_STORAGE
		}
	]
	
	return arr


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func lock() -> void:
	_locked = true

func is_locked() -> bool:
	return _locked

func clear() -> void:
	if not _locked:
		_db.clear()
		_dirty = true

func size() -> int:
	return _db.size()

func is_empty() -> bool:
	return _db.is_empty()

func is_dirty() -> bool:
	return _dirty

func clear_dirty() -> void:
	_dirty = false

func save(path : String) -> int:
	var res : int = OK
	res = ResourceSaver.save(self, path)
	if res == OK:
		_dirty = false
		saved.emit()
	return res

func get_component_type_list() -> Array:
	return _types.keys()

func get_component_list() -> Array:
	var items : Array = []
	for uuid in _db.keys():
		items.append({
			&"uuid": uuid,
			&"type":_db[uuid][&"type"],
			&"name":_db[uuid][&"name"],
			&"size_range":_db[uuid][&"size_range"]
		})
	return items

func get_component_list_of_type(type : StringName) -> Array:
	var items : Array = []
	if type in _types:
		for uuid in _types[type]:
			items.append({
				&"uuid": uuid,
				&"type":_db[uuid][&"type"],
				&"name":_db[uuid][&"name"],
				&"size_range":_db[uuid][&"size_range"]
			})
	return items

func has_component(uuid : StringName) -> bool:
	return uuid in _db

func get_component(uuid : StringName, duplicate : bool = false) -> Dictionary:
	if uuid in _db:
		if duplicate:
			return CSys.duplicate_component_data(_db[uuid])
		return _db[uuid]
	return {}

func duplicate_component(uuid : StringName, auto_store : bool = true) -> Dictionary:
	if uuid in _db:
		var nc : Dictionary = CSys.duplicate_component_data(_db[uuid], true)
		if auto_store:
			if add_component(nc) != OK:
				return {}
		return nc
	return {}

func remove_component(uuid : StringName) -> int:
	if _locked:
		return ERR_LOCKED
	if not uuid in _db:
		return ERR_DOES_NOT_EXIST
	
	if _db[uuid][&"type"] in _types:
		var idx : int = _types[_db[uuid][&"type"]].find(uuid)
		if idx >= 0:
			_types[_db[uuid][&"type"]].remove_at(idx)
			if _types[_db[uuid][&"type"]].size() <= 0:
				_types.erase(_db[uuid][&"type"])
	
	_db.erase(uuid)
	_dirty = true
	component_removed.emit(uuid)
	dirtied.emit()
	return OK

func set_database_dictionary(db : Dictionary, fail_on_warnings : bool = false) -> int:
	if _locked:
		return ERR_LOCKED
	_db.clear()
	for key in db:
		var result : int = add_component(db[key])
		if result != OK:
			if fail_on_warnings:
				printerr("Database object contains invalid data. Abandoning import.")
				_db.clear()
				_dirty = false
				return result
	
	# This is a sort of special-case method. It's assumed that the database is
	# not dirty after being set to the given DB dictionary.
	_dirty = false
	return OK

func add_component(def : Dictionary, allow_uuid_override : bool = false) -> int:
	if _locked:
		return ERR_LOCKED
	if &"uuid" in def:
		if not allow_uuid_override and def[&"uuid"] in _db:
			return ERR_ALREADY_EXISTS
	else:
		def[&"uuid"] = UUID.v4()
	
	var res : int = CSys.validate_component_data(def)
	if res != OK:
		return res
	if &"layout_list" in def:
		if def[&"layout_list"].get_typed_builtin() == TYPE_NIL:
			def[&"layout_list"] = Array(def[&"layout_list"], TYPE_INT, &"", null)
	
	# TODO: Possibly move this code to a dedicated method.
	if def[&"uuid"] in _db:
		var old_cmp : Dictionary = _db[def[&"uuid"]]
		if def[&"type"] != old_cmp[&"type"]:
			if old_cmp[&"type"] in _types:
				var idx : int = _types[old_cmp[&"type"]].find(old_cmp[&"uuid"])
				if idx >= 0:
					_types[old_cmp[&"type"]].remove_at(idx)
					if _types[old_cmp[&"type"]].size() <= 0:
						_types.erase(old_cmp[&"type"])
	
	_db[def[&"uuid"]] = def
	if not def[&"type"] in _types:
		_types[def[&"type"]] = []
	if _types[def[&"type"]].find(def[&"uuid"]) < 0:
		_types[def[&"type"]].append(def[&"uuid"])

	_dirty = true
	component_added.emit(def[&"uuid"])
	dirtied.emit()
	return OK
