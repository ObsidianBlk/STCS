@tool
extends MarginContainer


# --------------------------------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------------------------------
const INFOREQUESTDIALOG : PackedScene = preload("res://addons/Components/ui/info_request_dialog/InfoRequestDialog.tscn")

# --------------------------------------------------------------------------------------------------
# Variables
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
# Onready Variables
# --------------------------------------------------------------------------------------------------
@onready var _component_block : Control = $Columns/ComponentBlock


# --------------------------------------------------------------------------------------------------
# Override Methods
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
# Private Methods
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
# Public Methods
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
# Handler Methods
# --------------------------------------------------------------------------------------------------
func _on_AddDB_pressed():
	var info_dialog = INFOREQUESTDIALOG.instantiate()
	if info_dialog != null:
		info_dialog.label_text = "Enter new Component Database Name:"
		add_child(info_dialog)
		info_dialog.dialog_accepted.connect(_on_new_db_name)
		info_dialog.popup_centered()

func _on_new_db_name(db_name : String) -> void:
	if db_name.strip_edges() != "":
		var res : int = CCDB.create_database(db_name)
		if res != OK:
			printerr("Create Database failed with code: ", res)
	#print("The new DB name is: ", db_name)

func _on_new_component_requested() -> void:
	var data : Dictionary = CSys.create_component_data()
	_component_block.set_record(data)

func _on_component_selection_cleared() -> void:
	_component_block.clear()

func _on_component_selected(db_key : StringName, uuid : StringName) -> void:
	var cdb : ComponentDB = CCDB.get_database_by_key(db_key)
	if cdb != null:
		var data : Dictionary = cdb.get_component(uuid, true)
		if not data.is_empty():
			_component_block.set_record(data)
