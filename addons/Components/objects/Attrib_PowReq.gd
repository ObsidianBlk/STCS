@tool
extends "res://addons/Components/objects/ComponentAttribute.gd"


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANAME : StringName = &"pow_req"
const SCHEMA : Dictionary = {
	&"max":{&"req":true, &"type":TYPE_INT, &"min":1},
	&"req":{&"req":true, &"type":TYPE_INT, &"min":1},
	&"auto":{&"req":true, &"type":TYPE_BOOL} # Automatically recieve power without command requirement
}


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_name() -> StringName:
	return ANAME

func get_attribute_data() -> Dictionary:
	return {&"max":1, &"req":1, &"auto":false}

func duplicate_attribute_data(data : Dictionary) -> Dictionary:
	if validate_attribute_data(data) == OK:
		return {
			&"max": data[&"max"],
			&"req": data[&"req"],
			&"auto": data[&"auto"]
		}
	return {}

func create_instance(component : Dictionary) -> Dictionary:
	var auto_enabled : bool = component[&"attributes"][ANAME][&"auto"]
	var ainst : Dictionary = {
		&"power": 0
	}
	if component[&"attributes"][ANAME][&"auto"] == true:
		ainst[&"auto_enabled"] = true
	return ainst

func validate_attribute_data(data : Dictionary) -> int:
	var res : int = DSV.verify(data, SCHEMA)
	if res == OK:
		if data[&"max"] < data[&"req"]:
			return ERR_PARAMETER_RANGE_ERROR
	return OK

