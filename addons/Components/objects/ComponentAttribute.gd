@tool
extends RefCounted
class_name ComponentAttribute

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal response(msg)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_name() -> StringName:
	return &""

func get_instance_data(component : Dictionary) -> Dictionary:
	return {}

func validate_attribute_data(data : Dictionary) -> int:
	return OK

func handle_request(req : Dictionary, component : Dictionary, instance : Dictionary) -> void:
	pass

func handle_response(res : Dictionary, component : Dictionary, instance : Dictionary) -> void:
	pass
