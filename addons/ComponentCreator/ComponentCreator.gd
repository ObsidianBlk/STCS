@tool
extends EditorPlugin

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const AUTO_UUID_NAME : String = "UUID"
const CCMAIN : PackedScene = preload("res://addons/ComponentCreator/ui/main/Main.tscn")
const PLUGIN_ICON : Texture = preload("res://addons/ComponentCreator/assets/icons/plugin_icon.svg")

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _main_control : Control = null

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _enter_tree() -> void:
	add_autoload_singleton(AUTO_UUID_NAME, "res://addons/ComponentCreator/autos/UUID.gd")
	if _main_control == null:
		_main_control = CCMAIN.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(_main_control)
	_make_visible(false)


func _exit_tree() -> void:
	remove_autoload_singleton(AUTO_UUID_NAME)
	if _main_control != null:
		_main_control.queue_free()
		_main_control = null


func _make_visible(visible : bool) -> void:
	if _main_control != null:
		_main_control.visible = visible


func _has_main_screen() -> bool:
	return true


func _get_plugin_name():
	return "Component Creator"

func _get_plugin_icon():
	return PLUGIN_ICON
