@tool
extends EditorPlugin

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const AUTO_UUID_NAME : String = "UUID"
const AUTO_CCDB_NAME : String = "CCDB"
const MAIN_UI : PackedScene = preload("res://addons/Components/ui/component_database/component_database_main/ComponentDatabaseMain.tscn")
#preload("res://addons/Components/ui/data_control_main/DataControlMain.tscn")
const PLUGIN_ICON : Texture = preload("res://addons/Components/assets/icons/plugin_icon.svg")

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _main_ui : Control = null

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _enter_tree() -> void:
	#add_autoload_singleton(AUTO_UUID_NAME, "res://addons/STCSDataControl/autos/UUID.gd")
	#add_autoload_singleton(AUTO_CCDB_NAME, "res://addons/STCSDataControl/autos/CCDB.gd")
	if CSys.is_ready():
		CCDB.load_database_resources()
	else:
		CSys.readied.connect(func(): CCDB.load_database_resources())
		
	if _main_ui == null:
		_main_ui = MAIN_UI.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(_main_ui)
	_make_visible(false)


func _exit_tree() -> void:
	#remove_autoload_singleton(AUTO_CCDB_NAME)
	#remove_autoload_singleton(AUTO_UUID_NAME)
	if _main_ui != null:
		_main_ui.queue_free()
		_main_ui = null
	CCDB.clear(true)


func _make_visible(visible : bool) -> void:
	if _main_ui != null:
		_main_ui.visible = visible


func _has_main_screen() -> bool:
	return true


func _get_plugin_name():
	return "Components"

func _get_plugin_icon():
	return PLUGIN_ICON
