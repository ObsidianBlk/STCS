@tool
extends "res://addons/Components/objects/ComponentAttribute.gd"

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANAME : StringName = &"crew"
const SCHEMA : Dictionary = {
	&"max":{&"req":true, &"type":TYPE_INT, &"min":1},
	&"req":{&"req":true, &"type":TYPE_INT, &"min":1}
}


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_name() -> StringName:
	return ANAME

func get_attribute_data() -> Dictionary:
	return {&"max":1, &"req":1}

func validate_attribute_data(data : Dictionary) -> int:
	var res : int = DSV.verify(data, SCHEMA)
	if res == OK and data[&"max"] < data[&"req"]:
		return ERR_PARAMETER_RANGE_ERROR
	return res

func duplicate_attribute_data(data : Dictionary) -> Dictionary:
	if validate_attribute_data(data) == OK:
		return {
			&"max": data[&"max"],
			&"req": data[&"req"]
		}
	return {}

func create_instance(component : Dictionary) -> Dictionary:
	# Honestly, this may be way more complex than this. A crew member can have the state
	# of "injured"... and that would need to be represented... as well as "where they sit"
	# as a player may want to reassign an injured and/or uninjured crewmen.
	
	# A crew member may need to be a data object. Something like...
	# {&"department":"Engineering", &"health":100}
	# ... and these crew objects are assigned to a crew "seat", similar to Officers.
	return {
		&"assigned": 0
	}

func validate_instance_data(instance : Dictionary) -> int:
	if not &"assigned" in instance:
		return ERR_DATABASE_CANT_READ
	if typeof(instance[&"assigned"]) != TYPE_INT:
		return ERR_INVALID_DATA
	if instance[&"assigned"] < 0:
		return ERR_PARAMETER_RANGE_ERROR
	return OK

func duplicate_instance_data(instance : Dictionary) -> Dictionary:
	if validate_instance_data(instance) == OK:
		return {&"assigned": instance[&"assigned"]}
	return {}

