extends Resource
class_name ComponentDB


# --------------------------------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------------------------------
const COMPONENT_STRUCTURE : Dictionary = {
	&"name":{&"req":true, &"type":TYPE_STRING},
	&"color_primary":{&"req":true, &"type":TYPE_COLOR},
	&"color_secondary":{&"req":true, &"type":TYPE_COLOR},
	&"sp":{&"req":true, &"type":TYPE_INT},
	&"absorption":{&"req":true, &"type":TYPE_INT},
	&"bleed":{&"req":true, &"type":TYPE_INT},
	&"stress":{&"req":true, &"type":TYPE_INT},
	&"type":{&"req":true, &"type":TYPE_STRING_NAME},
	&"power":{&"req":false, &"type":TYPE_INT, &"default":0},
	&"crew":{&"req":false, &"type":TYPE_INT, &"default":0},
	&"size_range":{&"req":true, &"type":TYPE_VECTOR2I, &"minmax":true},
	&"seats":{&"req":false, &"type":TYPE_ARRAY, &"sub_type":TYPE_DICTIONARY},
	&"layout":{&"req":true, &"type":TYPE_DICTIONARY},
}

const SEAT_STRUCTURE : Dictionary = {
	&"type":{&"req":true, &"type":TYPE_STRING_NAME},
	&"rank":{&"req":true, &"type":TYPE_VECTOR2I, &"minmax":true}
}

const LAYOUT_STRUCTURE : Dictionary = {
	&"target":{&"req":true, &"type":TYPE_INT},
	&"list":{&"req":true, &"type":TYPE_ARRAY, &"sub_type":TYPE_INT}
}


# --------------------------------------------------------------------------------------------------
# "Export" Variables
# --------------------------------------------------------------------------------------------------
var _name : String = ""
var _db : Dictionary = {}

# --------------------------------------------------------------------------------------------------
# Variables
# --------------------------------------------------------------------------------------------------
var _tags : Dictionary = {}

# --------------------------------------------------------------------------------------------------
# Override Methods
# --------------------------------------------------------------------------------------------------
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


# --------------------------------------------------------------------------------------------------
# Private Methods
# --------------------------------------------------------------------------------------------------
func _VerifySeatStructure(data : Dictionary) -> Dictionary:
	var seat : Dictionary = {}
	for key in SEAT_STRUCTURE.keys():
		if key in data:
			var type : int = typeof(data[key])
			if type != SEAT_STRUCTURE[key][&"type"]:
				printerr("Seat definition property \"%s\" invalid type."%[key])
				return {}
			if type == TYPE_VECTOR2I and &"minmax" in SEAT_STRUCTURE[key]:
				if SEAT_STRUCTURE[key][&"minmax"] == true and data[key].x > data[key].y:
					printerr("Seat definition property \"%s\" range invalid."%[key])
					return {}
			seat[key] = data[key]
	return seat


# --------------------------------------------------------------------------------------------------
# Public Methods
# --------------------------------------------------------------------------------------------------
func clear() -> void:
	_db.clear()

func size() -> int:
	return _db.size()

func is_empty() -> bool:
	return _db.is_empty()

func set_database_dictionary(db : Dictionary, fail_on_warnings : bool = false) -> int:
	_db.clear()
	return OK

func add_component(def : Dictionary, allow_uuid_override : bool = false) -> int:
	var cmp : Dictionary = {&"uuid":&""}
	if &"uuid" in def:
		cmp[&"uuid"] = def[&"uuid"]
		if not allow_uuid_override and cmp[&"uuid"] in _db:
			return ERR_ALREADY_EXISTS
	else:
		cmp[&"uuid"] = UUID.v4()
	
	for key in COMPONENT_STRUCTURE.keys():
		if key in def:
			if typeof(def[key]) != COMPONENT_STRUCTURE[key][&"type"]:
				printerr("Component definition property \"%s\" invalid value type."%[key])
				return ERR_INVALID_DATA
			match COMPONENT_STRUCTURE[key][&"type"]:
				TYPE_INT:
					if def[key] < 0:
						printerr("Component property \"%s\" value out of range."%[key])
						return ERR_PARAMETER_RANGE_ERROR
					cmp[key] = def[key]
				TYPE_STRING:
					if def[key] == "":
						printerr("Component property \"%s\" is empty string."%[key])
						return ERR_PARAMETER_RANGE_ERROR
					cmp[key] = def[key]
				TYPE_STRING_NAME:
					if def[key] == &"":
						printerr("Component property \"%s\" is empty string."%[key])
						return ERR_PARAMETER_RANGE_ERROR
					cmp[key] = def[key]
				TYPE_VECTOR2I:
					if &"minmax" in COMPONENT_STRUCTURE[key]:
						if COMPONENT_STRUCTURE[key][&"minmax"] == true and def[key].x > def[key].y:
							printerr("Component property \"%s\" range invalid."%[key])
							return ERR_PARAMETER_RANGE_ERROR
					cmp[key] = def[key]
				TYPE_ARRAY:
					if key == &"seats":
						var seats : Array = []
						for item in def[key]:
							if typeof(item) != TYPE_DICTIONARY:
								printerr("Component property \"%s\" contains invalid entry type."%[key])
								return ERR_INVALID_DATA
							var seat = _VerifySeatStructure(item)
							if seat.empty():
								# NOTE: Don't need to print anything as _VerifySeatsStructure should do that already.
								return ERR_INVALID_DATA
							seats.append(seat)
						cmp[key] = seats
					# TODO: Figure out how to handle tagging
				TYPE_DICTIONARY:
					pass
				# TODO: Handle the SEAT and LAYOUT keys via TYPE_ARRAY and TYPE_DICTIONARY respectively.
		elif COMPONENT_STRUCTURE[key][&"req"] == true:
			printerr("Component definition missing required property \"%s\"."%[key])
			return ERR_DOES_NOT_EXIST
		elif &"default" in COMPONENT_STRUCTURE[key]:
			cmp[key] = COMPONENT_STRUCTURE[key][&"default"]
		
	_db[cmp[&"uuid"]] = cmp
	return OK
