@tool
extends RefCounted

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
func register() -> void:
	CSys.Register_Attrib_Schema(ANAME, SCHEMA)
	CSys.Register_Attrib(ANAME, self)

func has_instance_data() -> bool:
	return false

func get_instance_data(component : Dictionary) -> Dictionary:
	return {}

# ------------------------------------------------------------------------------
# "Exposed" Public Methods
# ------------------------------------------------------------------------------
func EX_get_power(component : Dictionary, instance : Dictionary) -> int:
	if not &"attributes" in component: return 0
	if not ANAME in component[&"attributes"]: return 0
	return component[ANAME][&"ppt"]



