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

func get_attribute_data() -> Dictionary:
	return {}

func create_instance(component : Dictionary) -> Dictionary:
	return {}

func duplicate_attribute_data(data : Dictionary) -> Dictionary:
	return {}

func validate_attribute_data(data : Dictionary) -> int:
	return OK

func validate_instance_data(instance : Dictionary) -> int:
	return OK

func handle_request(req : Dictionary, component : Dictionary, instance : Dictionary) -> void:
	pass

func handle_response(res : Dictionary, component : Dictionary, instance : Dictionary) -> void:
	pass
