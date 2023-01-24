@tool
extends "res://addons/Components/objects/ComponentAttribute.gd"


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANAME : StringName = &"pow_bat"
const SCHEMA : Dictionary = {
	&"points":{&"req":true, &"type":TYPE_INT, &"min":1}
}



# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_name() -> StringName:
	return ANAME

func get_instance_data(component : Dictionary) -> Dictionary:
	return {
		&"stored": 0
	}

func validate_attribute_data(data : Dictionary) -> int:
	return DSV.verify(data, SCHEMA)
