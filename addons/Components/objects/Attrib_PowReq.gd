@tool
extends "res://addons/Components/objects/ComponentAttribute.gd"


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANAME : StringName = &"pow_req"
const SCHEMA : Dictionary = {
	&"pmax":{&"req":true, &"type":TYPE_INT, &"min":1},
	&"preq":{&"req":true, &"type":TYPE_INT, &"min":1},
	&"auto":{&"req":true, &"type":TYPE_BOOL} # Automatically recieve power without command requirement
}


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_name() -> StringName:
	return ANAME

func get_instance_data(component : Dictionary) -> Dictionary:
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
		if data[&"pmax"] < data[&"preq"]:
			return ERR_PARAMETER_RANGE_ERROR
	return OK

