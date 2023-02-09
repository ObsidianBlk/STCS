@tool
extends "res://addons/Components/objects/ComponentAttribute.gd"


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANAME : StringName = &"officers"
enum RANK {Ensign=1, Lieutenant=2, LtCommander=3, Commander=4, Captain=5}
const SCHEMA : Dictionary = {
	&"list":{&"req":true, &"type":TYPE_ARRAY, &"item":{
			&"type":TYPE_DICTIONARY,
			&"def":{
				&"type":{&"req":true, &"type":TYPE_STRING_NAME, &"allow_empty":false},
				&"rank":{&"req":true, &"type":TYPE_VECTOR2I, &"minmax":true},
				&"cmd":{&"req":true, &"type":TYPE_BOOL}
			}
		}
	}
}

const INSTANCE_SCHEMA : Dictionary = {
	&"seats":{&"req":true, &"type":TYPE_ARRAY, &"item":{
			&"type":TYPE_STRING_NAME,
			&"allow_empty":true
		}
	}
}


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_name() -> StringName:
	return ANAME

func get_attribute_data() -> Dictionary:
	return {&"list":[]}

func validate_attribute_data(data : Dictionary) -> int:
	return DSV.verify(data, SCHEMA)

func duplicate_attribute_data(data : Dictionary) -> Dictionary:
	if validate_attribute_data(data) == OK:
		var list : Array = []
		for item in data[&"list"]:
			list.append({
				&"type": item[&"type"],
				&"rank": item[&"rank"]
			})
		return {&"list": list}
	return {}

func create_instance(component : Dictionary) -> Dictionary:
	var seats : Array = []
	for i in range(component[&"attributes"][ANAME][&"list"].size()):
		seats.append({
			&"oid":&""
		})
	return {&"seats":seats}

func validate_instance_data(instance : Dictionary) -> int:
	return DSV.verify(instance, INSTANCE_SCHEMA)

func duplicate_instance_data(instance : Dictionary) -> Dictionary:
	if DSV.verify(instance, INSTANCE_SCHEMA) == OK:
		var seats : Array = []
		for oid in instance[&"seats"]:
			seats.append(oid)
		return {&"seats": seats}
	return {}
