@tool
extends EditorPlugin

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const AUTO_UUID_NAME : String = "UUID"
const AUTO_CCDB_NAME : String = "CCDB"
const DCMAIN : PackedScene = preload("res://addons/STCSDataControl/ui/data_control_main/DataControlMain.tscn")
const PLUGIN_ICON : Texture = preload("res://addons/STCSDataControl/assets/icons/plugin_icon.svg")

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _main_control : Control = null

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _enter_tree() -> void:
	#add_autoload_singleton(AUTO_UUID_NAME, "res://addons/STCSDataControl/autos/UUID.gd")
	#add_autoload_singleton(AUTO_CCDB_NAME, "res://addons/STCSDataControl/autos/CCDB.gd")
	CCDB.load_database_resources()
	if _main_control == null:
		_main_control = DCMAIN.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(_main_control)
	_make_visible(false)


func _exit_tree() -> void:
	#remove_autoload_singleton(AUTO_CCDB_NAME)
	#remove_autoload_singleton(AUTO_UUID_NAME)
	if _main_control != null:
		_main_control.queue_free()
		_main_control = null
	CCDB.clear(true)


func _make_visible(visible : bool) -> void:
	if _main_control != null:
		_main_control.visible = visible


func _has_main_screen() -> bool:
	return true


func _get_plugin_name():
	return "STCS Data Control"

func _get_plugin_icon():
	return PLUGIN_ICON
