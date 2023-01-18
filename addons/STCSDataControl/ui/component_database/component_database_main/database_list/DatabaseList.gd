extends Control


# --------------------------------------------------------------------------------------------------
# Signals
# --------------------------------------------------------------------------------------------------
signal database_selected(db_key)

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
@onready var db_tree : Tree = $Databases/Scroll/Tree

# --------------------------------------------------------------------------------------------------
# Override Methods
# --------------------------------------------------------------------------------------------------
func _ready() -> void:
	CCDB.database_added.connect(_on_db_added)
	CCDB.database_dropped.connect(_on_db_dropped)

# --------------------------------------------------------------------------------------------------
# Private Methods
# --------------------------------------------------------------------------------------------------
func _RebuildDatabaseTree() -> void:
	db_tree.clear()
	var root : TreeItem = db_tree.create_item()
	db_tree.hide_root = true
	for path_id in CCDB.CDB_PATH.keys():
		var dbcoll : TreeItem = db_tree.create_item(root)
		dbcoll.set_text(0, path_id)
		dbcoll.set_metadata(0, path_id)
		for item in CCDB.get_database_list(path_id):
			var dbitem : TreeItem = db_tree.create_item(dbcoll)
			dbitem.set_text(0, item[&"name"])
			dbitem.set_metadata(0, item[&"key"])

func _FindCollectionTreeItem(path_id : StringName) -> TreeItem:
	var root : TreeItem = db_tree.get_root()
	for child in root.get_children():
		if child.get_metadata(0) == path_id:
			return child
	return null

# --------------------------------------------------------------------------------------------------
# Public Methods
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
# Handler Methods
# --------------------------------------------------------------------------------------------------
func _on_db_added(db_key : StringName, db_name : String) -> void:
	var path_id : StringName = CCDB.get_database_path_id_by_key(db_key)
	if path_id != &"":
		var coll : TreeItem = _FindCollectionTreeItem(path_id)
		if coll != null:
			var dbitem : TreeItem = db_tree.create_item(coll)
			dbitem.set_text(0, db_name)
			dbitem.set_metadata(0, db_key)

func _on_db_dropped(db_key : StringName, db_name : String) -> void:
	pass


func _on_add_db_pressed() -> void:
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
	else:
		printerr("Create Database failed... name empty or contains only whitespace.")

func _on_rem_db_pressed() -> void:
	pass # Replace with function body.


