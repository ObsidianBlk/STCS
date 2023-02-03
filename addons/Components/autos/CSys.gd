@tool
extends Node

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ATTRIB_OBJECTS : Array = [
	preload("res://addons/Components/objects/Attrib_PowGen.gd"),
	preload("res://addons/Components/objects/Attrib_PowReq.gd"),
	preload("res://addons/Components/objects/Attrib_PowBat.gd"),
	preload("res://addons/Components/objects/Attrib_Engine.gd"),
	preload("res://addons/Components/objects/Attrib_Crew.gd"),
	preload("res://addons/Components/objects/Attrib_Officers.gd"),
]

enum COMPONENT_LAYOUT_TYPE {Static=0, Cluster=1, Growable=2}
const COMPONENT_STRUCTURE : Dictionary = {
	&"uuid":{&"req":true, &"type":TYPE_STRING_NAME},
	&"name":{&"req":true, &"type":TYPE_STRING},
	&"type":{&"req":true, &"type":TYPE_STRING_NAME},
	&"max_sp":{&"req":true, &"type":TYPE_INT},
	&"absorption":{&"req":true, &"type":TYPE_INT},
	&"bleed":{&"req":true, &"type":TYPE_INT},
	&"max_stress":{&"req":true, &"type":TYPE_INT},
	&"layout_type":{&"req":true, &"type":TYPE_INT, &"min":0, &"max":2},
	&"layout_list":{&"req":false, &"type":TYPE_ARRAY, &"item":{&"type":TYPE_INT}},
	&"size_range":{&"req":true, &"type":TYPE_VECTOR2I, &"minmax":true},
	&"attributes":{&"req":false, &"type":TYPE_DICTIONARY}
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _attribs : Dictionary = {}

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	for att in ATTRIB_OBJECTS:
		var atti = att.new()
		if atti is ComponentAttribute:
			var aname : StringName = atti.get_name()
			if aname != &"" and not aname in _attribs:
				_attribs[aname] = atti
				atti.response.connect(_on_attribute_response)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
#func validate_attribute_data(attrib_name : StringName, data : Dictionary) -> int:
#	if not attrib_name in _attribs:
#		return ERR_DATABASE_CANT_READ
#	return _attribs[attrib_name].validate_attribute_data(data)

func create_component_data() -> Dictionary:
	return {
		&"uuid":UUID.v4(),
		&"name":"Component",
		&"type":&"Component",
		&"max_sp":10,
		&"absorption":4,
		&"bleed":2,
		&"max_stress":4,
		&"layout_type":COMPONENT_LAYOUT_TYPE.Static,
		&"layout_list":Array([int(1)], TYPE_INT, &"", null),
		&"size_range":Vector2i(1,1),
	}

func duplicate_component_data(component : Dictionary, new_uuid : bool = false) -> Dictionary:
	if validate_component_data(component, true) == OK:
		var dup : Dictionary = {
			&"uuid": UUID.v4() if new_uuid else component[&"uuid"],
			&"name": component[&"name"],
			&"type": component[&"type"],
			&"max_sp": component[&"max_sp"],
			&"absorption": component[&"absorption"],
			&"bleed": component[&"bleed"],
			&"max_stress": component[&"max_stress"],
			&"layout_type": component[&"layout_type"],
			&"size_range": component[&"size_range"]
		}
		if dup[&"layout_type"] == COMPONENT_LAYOUT_TYPE.Static:
			dup[&"layout_list"] = Array(component[&"layout_list"], TYPE_INT, &"", null)
		
		if &"attributes" in component:
			dup[&"attributes"] = {}
			for attrib_name in component[&"attributes"].keys():
				if not attrib_name in _attribs:
					printerr("Cannot duplicate attribute \"%s\". Attribute is unknown."%[attrib_name])
				else:
					dup[&"attributes"][attrib_name] = \
						_attribs[attrib_name].duplicate_attribute_data(
							component[&"attributes"][attrib_name]
						)
		return dup
	return {}

func validate_component_data(component : Dictionary, ignore_attribs : bool = false) -> int:
	var res : int = DSV.verify(component, COMPONENT_STRUCTURE)
	if res != OK:
		return res
	
	if &"attributes" in component and not ignore_attribs: # Special handlers!
		for attrib_name in component[&"attributes"].keys():
			if not attrib_name in _attribs:
				printerr("Unknown attribute \"%s\"."%[attrib_name])
				return ERR_INVALID_PARAMETER
			res = _attribs[attrib_name].validate_attribute_data(
				component[&"attributes"][attrib_name]
			)
			if res != OK:
				return res
	return OK

func get_attribute_handler(attrib_name : StringName) -> ComponentAttribute:
	if attrib_name in _attribs:
		return _attribs[attrib_name]
	return null

func create_instance(db_name : StringName, uuid : StringName) -> Dictionary:
	var inst : Dictionary = {}
	var db : ComponentDB = CCDB.get_database_by_key(db_name)
	if db != null:
		var cmp : Dictionary = db.get_component(uuid)
		if not cmp.is_empty():
			inst = {
				&"db_name": db_name,
				&"uuid": uuid,
				&"sp": cmp[&"max_sp"],
				&"stress": 0,
				&"attributes": {}
			}
			if &"attributes" in cmp:
				for akey in cmp[&"Attributes"]:
					if akey in _attribs:
						var idat : Dictionary = _attribs[akey].create_instance(cmp)
						if not idat.is_empty():
							inst[&"attributes"][akey] = idat
	return inst

func exec(op : StringName, instance : Dictionary, default = null):
	pass

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
func _on_attribute_response(msg : Dictionary) -> void:
	pass


