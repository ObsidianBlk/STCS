@tool
extends Control


# --------------------------------------------------------------------------------------------------
# Signals
# --------------------------------------------------------------------------------------------------
signal database_selected(db_key)

# --------------------------------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------------------------------
const INFOREQUESTDIALOG : PackedScene = preload("res://addons/Components/ui/info_request_dialog/InfoRequestDialog.tscn")
const CONFIRMDIALOG : PackedScene = preload("res://addons/Components/ui/confirm_dialog/ConfirmDialog.tscn")

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
	_RebuildDatabaseTree()

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
		dbcoll.set_selectable(0, false)
		for item in CCDB.get_database_list(path_id):
			var dbitem : TreeItem = db_tree.create_item(dbcoll)
			dbitem.set_text(0, item[&"name"])
			dbitem.set_metadata(0, item[&"key"])

func _FindCollectionTreeItem(path_id : StringName) -> TreeItem:
	var root : TreeItem = db_tree.get_root()
	if root != null:
		for child in root.get_children():
			if child.get_metadata(0) == path_id:
				return child
	return null

func _DisplayConfirmDialog(msg : String) -> void:
	var dialog = CONFIRMDIALOG.instantiate()
	dialog.text = msg
	dialog.ok_only = true
	add_child(dialog)
	dialog.popup_centered()

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
	var sel : TreeItem = db_tree.get_selected()
	var root : TreeItem = db_tree.get_root()
	for coll in root.get_children():
		for entry in coll.get_children():
			if entry.get_metadata(0) == db_key:
				if entry == sel:
					db_tree.deselect_all()
					database_selected.emit(&"")
				entry.free()

func _on_add_db_pressed() -> void:
	var info_dialog = INFOREQUESTDIALOG.instantiate()
	if info_dialog != null:
		info_dialog.label_text = "Enter new Component Database Name:"
		add_child(info_dialog)
		info_dialog.dialog_accepted.connect(_on_new_db_name)
		info_dialog.popup_centered()
	else:
		printerr("Failed to open dialog box")

func _on_new_db_name(db_name : String) -> void:
	if db_name.strip_edges() != "":
		var res : int = CCDB.create_database(db_name)
		if res != OK:
			match res:
				ERR_UNCONFIGURED:
					_DisplayConfirmDialog.call_deferred("Database name is empty")
				ERR_ALREADY_EXISTS, ERR_ALREADY_IN_USE:
					_DisplayConfirmDialog.call_deferred("Database \"%s\" already exists."%[db_name])
					#_DisplayConfirmDialog("Database \"%s\" already exists."%[db_name])
				_:
					_DisplayConfirmDialog.call_deferred("Unrecognized error occured: Error code %s"%[res])
	else:
		printerr("Create Database failed... name empty or contains only whitespace.")

func _on_rem_db_pressed() -> void:
	var sel : TreeItem = db_tree.get_selected()
	if sel != null:
		var dialog = CONFIRMDIALOG.instantiate()
		dialog.yes_pressed.connect(_on_remove_yes_pressed)
		dialog.text = "About to permanently remove selected database. Are you sure?"
		add_child(dialog)
		dialog.popup_centered()
	else:
		_DisplayConfirmDialog("No database selected.")

func _on_remove_yes_pressed() -> void:
	var sel : TreeItem = db_tree.get_selected()
	if sel == null:
		printerr("No database selected.")
		return
	var db_key : StringName = sel.get_metadata(0)
	CCDB.erase_database_by_key(db_key)

func _on_tree_item_selected():
	var item : TreeItem = db_tree.get_selected()
	if item == null: return
	database_selected.emit(item.get_metadata(0))
