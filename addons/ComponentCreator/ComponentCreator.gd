@tool
extends EditorPlugin

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const AUTO_UUID_NAME : String = "UUID"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _uuid_preloaded : bool = false

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _enter_tree() -> void:
	if get_node_or_null("/root/%s"%[AUTO_UUID_NAME]) == null:
		add_autoload_singleton(AUTO_UUID_NAME, "res://addons/ComponentCreator/autos/UUID.gd")
	else:
		_uuid_preloaded = true


func _exit_tree() -> void:
	if not _uuid_preloaded:
		remove_autoload_singleton(AUTO_UUID_NAME)
	_uuid_preloaded = false


