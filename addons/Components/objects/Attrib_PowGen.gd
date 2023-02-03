@tool
extends "res://addons/Components/objects/ComponentAttribute.gd"



# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANAME : StringName = &"pow_gen"
const SCHEMA : Dictionary = {
	&"ppt":{&"req":true, &"type":TYPE_INT, &"min":1}
}

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_name() -> StringName:
	return ANAME

func get_attribute_data() -> Dictionary:
	return {&"ppt":1}

func duplicate_attribute_data(data : Dictionary) -> Dictionary:
	if validate_attribute_data(data) == OK:
		return {&"ppt": data[&"ppt"]}
	return {}

func validate_attribute_data(data : Dictionary) -> int:
	return DSV.verify(data, SCHEMA)

func handle_request(req : Dictionary, component : Dictionary, instance : Dictionary) -> void:
	# NOTE: This method is assuming req, component, and instance are formatted properly.
	#  after all, this script shouldn't be readibly available to the game at large.
	if req[&"request"] == ANAME:
		response.emit({
			&"from" : ANAME,
			&"power" : component[ANAME][&"ppt"]
		})

