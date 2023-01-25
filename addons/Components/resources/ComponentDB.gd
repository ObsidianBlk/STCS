@tool
extends Resource
class_name ComponentDB


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal component_added(uuid)
signal component_removed(uuid)
signal saved()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
#enum COMPONENT_LAYOUT_TYPE {Static=0, Cluster=1, Growable=2}
#const COMPONENT_STRUCTURE : Dictionary = {
#	&"name":{&"req":true, &"type":TYPE_STRING},
#	&"type":{&"req":true, &"type":TYPE_STRING_NAME},
#	&"max_sp":{&"req":true, &"type":TYPE_INT},
#	&"absorption":{&"req":true, &"type":TYPE_INT},
#	&"bleed":{&"req":true, &"type":TYPE_INT},
#	&"max_stress":{&"req":true, &"type":TYPE_INT},
#	&"layout_type":{&"req":true, &"type":TYPE_INT, &"min":0, &"max":2},
#	&"layout_list":{&"req":false, &"type":TYPE_ARRAY, &"item":{&"type":TYPE_INT}},
#	&"size_range":{&"req":true, &"type":TYPE_VECTOR2I, &"minmax":true},
#	&"attributes":{&"req":false, &"type":TYPE_DICTIONARY}
#}

#const ATTRIBUTE_STRUCTURES : Dictionary = {
#	&"pow_gen":{
#		&"ppt":{&"req":true, &"type":TYPE_INT, &"min":1}
#	},
#	&"pow_req":{
#		&"pmax":{&"req":true, &"type":TYPE_INT, &"min":1},
#		&"preq":{&"req":true, &"type":TYPE_INT, &"min":1},
#		&"auto":{&"req":true, &"type":TYPE_BOOL} # Automatically recieve power without command requirement
#	},
#	&"pow_bat":{
#		&"points":{&"req":true, &"type":TYPE_INT, &"min":1}
#	},
#	&"engine":{
#		&"mpt":{&"req":true, &"type":TYPE_INT, &"min":1}
#	},
#	&"crew_req":{
#		&"cmax":{&"req":true, &"type":TYPE_INT, &"min":1},
#		&"creq":{&"req":true, &"type":TYPE_INT, &"min":1}
#	},
#	&"seats":{
#		&"list":{&"req":true, &"type":TYPE_ARRAY, &"item":{
#				&"type":TYPE_DICTIONARY,
#				&"def":{
#					&"type":{&"req":true, &"type":TYPE_STRING_NAME},
#					&"rank":{&"req":true, &"type":TYPE_VECTOR2I, &"minmax":true}
#				}
#			}
#		}
#	}
#}


#static func get_empty_entry() -> Dictionary:
#	var entry : Dictionary = {}
#	for key in COMPONENT_STRUCTURE.keys():
#		var item : Dictionary = COMPONENT_STRUCTURE[key]
#		if item[&"req"] == true:
#			match item[&"type"]:
#				TYPE_INT:
#					entry[key] = 0
#				TYPE_STRING:
#					entry[key] = ""
#				TYPE_STRING_NAME:
#					entry[key] = &""
#				TYPE_VECTOR2I:
#					entry[key] = Vector2i.ZERO
#	return entry


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
	print("Attempting to save to: ", path)
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

func get_component(uuid : StringName) -> Dictionary:
	if uuid in _db:
		return _db[uuid]
	return {}

func remove_component(uuid : StringName) -> int:
	if _locked:
		return ERR_LOCKED
	if not uuid in _db:
		return ERR_DOES_NOT_EXIST
	_db.erase(uuid)
	_dirty = true
	component_removed.emit(uuid)
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
				return result
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
#	var res : int = DSV.verify(def, COMPONENT_STRUCTURE)
#	if res != OK:
#		return res
#
#	if &"attributes" in def: # Special handlers!
#		for attrib in def[&"attributes"].keys():
#			var attrib_handler : ComponentAttribute = CSys.get_attribute_handler(attrib)
#			if attrib_handler == null:
#				printerr("Unknown attribute \"%s\"."%[attrib])
#				return ERR_INVALID_PARAMETER
#			res = attrib_handler.validate_attribute_data(def[&"attributes"][attrib])
#			if res != OK:
#				return res
#			if not attrib in ATTRIBUTE_STRUCTURES:
#				printerr("Unknown attribute \"%s\"."%[attrib])
#				return ERR_INVALID_PARAMETER
#			res = DSV.verify(def[&"attributes"][attrib], ATTRIBUTE_STRUCTURES[attrib])
#			if res != OK:
#				return res
	
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
	_types[def[&"type"]].append(def[&"uuid"])

	_dirty = true
	component_added.emit(def[&"uuid"])
	return OK
