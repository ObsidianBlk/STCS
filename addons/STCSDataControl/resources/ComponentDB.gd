extends Resource
class_name ComponentDB


# --------------------------------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------------------------------
enum COMPONENT_LAYOUT_TYPE {Static=0, Cluster=1, Growable=2}
const COMPONENT_STRUCTURE : Dictionary = {
	&"name":{&"req":true, &"type":TYPE_STRING},
	&"sp":{&"req":true, &"type":TYPE_INT},
	&"absorption":{&"req":true, &"type":TYPE_INT},
	&"bleed":{&"req":true, &"type":TYPE_INT},
	&"stress":{&"req":true, &"type":TYPE_INT},
	&"type":{&"req":true, &"type":TYPE_STRING_NAME},
	&"power":{&"req":false, &"type":TYPE_INT, &"default":0},
	&"crew":{&"req":false, &"type":TYPE_INT, &"default":0},
	&"size_range":{&"req":true, &"type":TYPE_VECTOR2I, &"minmax":true},
	&"seats":{&"req":false, &"type":TYPE_ARRAY, &"sub_type":TYPE_DICTIONARY},
	&"layout_type":{&"req":true, &"type":TYPE_INT},
	&"layout_list":{&"req":false, &"type":TYPE_ARRAY},
	&"attributes":{&"req":false, &"type":TYPE_DICTIONARY}
}

const SEAT_STRUCTURE : Dictionary = {
	&"type":{&"req":true, &"type":TYPE_STRING_NAME},
	&"rank":{&"req":true, &"type":TYPE_VECTOR2I, &"minmax":true}
}


static func get_empty_entry() -> Dictionary:
	var entry : Dictionary = {}
	for key in COMPONENT_STRUCTURE.keys():
		var item : Dictionary = COMPONENT_STRUCTURE[key]
		if item[&"req"] == true:
			match item[&"type"]:
				TYPE_INT:
					entry[key] = 0
				TYPE_STRING:
					entry[key] = ""
				TYPE_STRING_NAME:
					entry[key] = &""
				TYPE_VECTOR2I:
					entry[key] = Vector2i.ZERO
	return entry


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
		if not typeof(key) == TYPE_STRING_NAME:
			printerr("Seat definition property key type invalid.")
			return {}
		
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

#func _VerifyLayoutStructure(data : Dictionary) -> Dictionary:
#	var layout : Dictionary = {}
#	for key in LAYOUT_STRUCTURE.keys():
#		if not typeof(key) == TYPE_STRING_NAME:
#			printerr("Seat definition property key type invalid.")
#			return {}
#
#		if key in data:
#			if typeof(data[key]) != LAYOUT_STRUCTURE[key][&"type"]:
#				printerr("Layout definition property \"%s\" invalid type."%[key])
#				return {}
#			if key == &"list":
#				var list : Array = []
#				for item in data[key]:
#					if item >= 0 and item < 6:
#						list.append(item)
#					else:
#						printerr("Layout definition property \"%s\" item value out of range."%[key])
#						return {}
#				layout[key] = list
#			else:
#				layout[key] = data[key]
#	return layout

func _VerifyAttributes(data : Dictionary) -> Dictionary:
	var attrib : Dictionary = {}
	for key in data.keys():
		if not typeof(key) == TYPE_STRING_NAME:
			printerr("Seat definition property key type invalid.")
			return {}
		# TODO: Check if value is only within a small set of TYPE_*s
		attrib[key] = data[key]
	return attrib

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
	for key in db:
		var result : int = add_component(db[key])
		if result != OK:
			if fail_on_warnings:
				printerr("Database object contains invalid data. Abandoning import.")
				_db.clear()
				return result
	return OK

func add_component(def : Dictionary, allow_uuid_override : bool = false) -> int:
	var cmp : Dictionary = {&"uuid":&""}
	if &"uuid" in def:
		cmp[&"uuid"] = def[&"uuid"]
		if not allow_uuid_override and cmp[&"uuid"] in _db:
			return ERR_ALREADY_EXISTS
	else:
		cmp[&"uuid"] = UUID.v4()
	
	var layout_list_req : bool = false
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
					if key == &"layout_type":
						if not COMPONENT_LAYOUT_TYPE.values().find(def[key]) >= 0:
							printerr("Component property \"%s\" value out of range."%[key])
							return ERR_PARAMETER_RANGE_ERROR
						layout_list_req = (def[key] == COMPONENT_LAYOUT_TYPE.Static)
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
					match key:
						&"seats":
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
						&"layout_list":
							if layout_list_req == true:
								var item_count : int = (cmp[&"size_range"].y - cmp[&"size_range"].x) + 1
								if def[key].size() != item_count:
									printerr("Component property \"%s\" missing required number of values."%[key])
									return ERR_PARAMETER_RANGE_ERROR
								var llist : Array = []
								for item in def[key]:
									if typeof(item) != TYPE_INT:
										printerr("Component property \"%s\" contains invalid entry type."%[key])
										return ERR_INVALID_DATA
									if item <= 0 or item > 0x7F:
										printerr("Component property \"%s\" entry value out of range."%[key])
										return ERR_PARAMETER_RANGE_ERROR
									llist.append(item)
								cmp[key] = llist
					# TODO: Figure out how to handle tagging
				TYPE_DICTIONARY:
					match key:
#						&"layout":
#							if layout_def_req == true:
#								var layout_def : Dictionary = _VerifyLayoutStructure(def[key])
#								if layout_def.is_empty():
#									# NOTE: Don't need to print anything as _VerifyLayoutStructure should do that already.
#									return ERR_INVALID_DATA
#								cmp[key] = layout_def
						&"attributes":
							var attrib : Dictionary = _VerifyAttributes(def[key])
							if attrib.is_empty():
								return ERR_INVALID_DATA
							cmp[key] = attrib
		elif COMPONENT_STRUCTURE[key][&"req"] == true:
			printerr("Component definition missing required property \"%s\"."%[key])
			return ERR_DOES_NOT_EXIST
		else:
			if key == &"layout_list" and layout_list_req == true:
				printerr("Component definition missing required property \"%s\"."%[key])
				return ERR_DOES_NOT_EXIST
			if &"default" in COMPONENT_STRUCTURE[key]:
				cmp[key] = COMPONENT_STRUCTURE[key][&"default"]
		
	_db[cmp[&"uuid"]] = cmp
	return OK
