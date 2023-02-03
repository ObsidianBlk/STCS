@tool
extends "res://addons/Components/objects/ComponentAttribute.gd"


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANAME : StringName = &"engine"
const SCHEMA : Dictionary = {
	&"mpt":{&"req":true, &"type":TYPE_INT, &"min":1}
}


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_name() -> StringName:
	return ANAME

func get_attribute_data() -> Dictionary:
	return {&"mpt":1}

func duplicate_attribute_data(data : Dictionary) -> Dictionary:
	if validate_attribute_data(data) == OK:
		return {&"mpt": data[&"mpt"]}
	return {}

func create_instance(component : Dictionary) -> Dictionary:
	return {}

func validate_attribute_data(data : Dictionary) -> int:
	return DSV.verify(data, SCHEMA)

