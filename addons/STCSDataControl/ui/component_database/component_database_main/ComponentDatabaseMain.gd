@tool
extends MarginContainer


# --------------------------------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------------------------------
const INFOREQUESTDIALOG : PackedScene = preload("res://addons/STCSDataControl/ui/info_request_dialog/InfoRequestDialog.tscn")

# --------------------------------------------------------------------------------------------------
# Variables
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
# Onready Variables
# --------------------------------------------------------------------------------------------------

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
	print("The new DB name is: ", db_name)
