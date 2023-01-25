@tool
extends "res://addons/Components/objects/ComponentAttribute.gd"


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANAME : StringName = &"crew"
const SCHEMA : Dictionary = {
	&"list":{&"req":true, &"type":TYPE_ARRAY, &"item":{
			&"type":TYPE_DICTIONARY,
			&"def":{
				&"type":{&"req":true, &"type":TYPE_STRING_NAME},
				&"rank":{&"req":true, &"type":TYPE_VECTOR2I, &"minmax":true}
			}
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

func create_instance(component : Dictionary) -> Dictionary:
	var seats : Array = []
	for i in range(component[&"attributes"][ANAME][&"list"].size()):
		seats.append({
			&"oid":&""
		})
	return {&"seats":seats}

func validate_attribute_data(data : Dictionary) -> int:
	return DSV.verify(data, SCHEMA)


