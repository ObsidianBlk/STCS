@tool
extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal component_selected(db_key, uuid)
signal selection_cleared()
signal new_component_requested()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const INFOREQUESTDIALOG : PackedScene = preload("res://addons/Components/ui/info_request_dialog/InfoRequestDialog.tscn")
const CONFIRMDIALOG : PackedScene = preload("res://addons/Components/ui/confirm_dialog/ConfirmDialog.tscn")

const TOOL_ADD : int = 0
const TOOL_REMOVE : int = 1
const TOOL_DUPLICATE : int = 2
const TOOL_HOLD : int = 3

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _db_key : StringName = &""
var _db : WeakRef = weakref(null)

var _held_component : Dictionary = {
	&"db_key": &"",
	&"uuid": &""
}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _comp_tree : Tree = $Components/Scroll/Tree
@onready var _tools_btn : MenuButton = $ctrls/Tools
@onready var _move_btn = $ctrls/MoveC



func _ready() -> void:
	var tpop : PopupMenu = _tools_btn.get_popup()
	if tpop != null:
		tpop.id_pressed.connect(_on_tool_id_pressed)
	_move_btn.visible = false

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetTypeItem(type : StringName, create_if_missing : bool = false) -> TreeItem:
	var root : TreeItem = _comp_tree.get_root()
	if root != null:
		for child in root.get_children():
			if child.get_metadata(0) == type:
				return child
		if create_if_missing == true:
			var coll : TreeItem = _comp_tree.create_item(root)
			coll.set_text(0, type)
			coll.set_metadata(0, type)
			coll.set_selectable(0, false)
			return coll
	return null

func _GetCompEntryItem(comp : Dictionary) -> TreeItem:
	if comp.is_empty(): return null
	var coll : TreeItem = _GetTypeItem(comp[&"type"], true)
	if coll == null: return null
	
	for child in coll.get_children():
		var md = child.get_metadata(0)
		if typeof(md) == TYPE_STRING_NAME:
			if md == comp[&"uuid"]:
				return child
	return null

func _AddComponentToTree(comp : Dictionary) -> TreeItem:
	var item : TreeItem = _GetCompEntryItem(comp)
	if item != null:
		item.set_text(0, comp[&"name"])
	else:
		if comp.is_empty(): return null
		var coll : TreeItem = _GetTypeItem(comp[&"type"], true)
		if coll == null: return null
		
		item = _comp_tree.create_item(coll)
		item.set_text(0, comp[&"name"])
		item.set_metadata(0, comp[&"uuid"])
		item.select(0)
	return item

func _RemoveComponent() -> void:
	var item = _comp_tree.get_selected()
	if item == null:
		_DisplayConfirmDialog("No component item selected.")
		return
	
	var db : ComponentDB = _db.get_ref()
	if db == null:
		_DisplayConfirmDialog("No component database selected.")
		return

	var comp : Dictionary = db.get_component(item.get_metadata(0))
	if comp.is_empty():
		_DisplayConfirmDialog("Selected component not found in the active database!")
		return
	
	var dialog = CONFIRMDIALOG.instantiate()
	dialog.text = "This will remove component \"%s\" from the database. Are you sure?"%[comp[&"name"]]
	dialog.yes_pressed.connect(_on_rem_component_confirmed.bind(comp))
	add_child(dialog)
	dialog.popup_centered.call_deferred()

func _DuplicateComponent() -> void:
	var item = _comp_tree.get_selected()
	if item == null:
		_DisplayConfirmDialog("No component item selected.")
		return
	
	var db : ComponentDB = _db.get_ref()
	if db == null:
		_DisplayConfirmDialog("No component database selected.")
		return
	
	db.duplicate_component(item.get_metadata(0))

func _HoldComponent() -> void:
	var item = _comp_tree.get_selected()
	if item == null:
		_DisplayConfirmDialog("No component item selected.")
		return
	
	var db : ComponentDB = _db.get_ref()
	if db == null:
		_DisplayConfirmDialog("No component database selected.")
		return
	
	if _held_component[&"uuid"] != item.get_metadata(0):	
		_held_component[&"db_key"] = _db_key
		_held_component[&"uuid"] = item.get_metadata(0)
		_move_btn.visible = true
	else:
		_held_component[&"db_key"] = &""
		_held_component[&"uuid"] = &""
		_move_btn.visible = false

func _ClearHeldComponent() -> void:
	_held_component[&"db_key"] = &""
	_held_component[&"uuid"] = &""
	_move_btn.visible = false

func _BuildTree(db : ComponentDB) -> void:
	_comp_tree.clear()
	var root : TreeItem = _comp_tree.create_item()
	_comp_tree.hide_root = true
	var types_list : Array = db.get_component_type_list()
	for type in types_list:
		var comp_list : Array = db.get_component_list_of_type(type)
		for comp in comp_list:
			_AddComponentToTree(comp)


func _SwapConnectedDB(odb : ComponentDB, ndb : ComponentDB) -> void:
	if odb != null:
		if odb.component_added.is_connected(_on_component_added):
			odb.component_added.disconnect(_on_component_added)
		if odb.component_removed.is_connected(_on_component_removed):
			odb.component_removed.disconnect(_on_component_removed)
	if ndb != null:
		if not ndb.component_added.is_connected(_on_component_added):
			ndb.component_added.connect(_on_component_added)
		if not ndb.component_removed.is_connected(_on_component_removed):
			ndb.component_removed.connect(_on_component_removed)

func _DisplayConfirmDialog(msg : String) -> void:
	var dialog = CONFIRMDIALOG.instantiate()
	dialog.text = msg
	dialog.ok_only = true
	add_child(dialog)
	dialog.popup_centered()


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_database_components(db_key : StringName) -> void:
	if db_key == _db_key: return
	
	if db_key != &"":
		var db : ComponentDB = CCDB.get_database_by_key(db_key)
		if db != null:
			selection_cleared.emit()
			_db_key = db_key
			_SwapConnectedDB(_db.get_ref(), db)
			_db = weakref(db)
			_BuildTree(db)
	else:
		selection_cleared.emit()
		_SwapConnectedDB(_db.get_ref(), null)
		_db = weakref(null)
		_db_key = &""
		_comp_tree.clear()


func add_component_to_database(comp : Dictionary) -> int:
	var db : ComponentDB = _db.get_ref()
	if db == null: return ERR_UNAVAILABLE
	var res : int = db.add_component(comp, true)
#	if res == OK:
#		var item : TreeItem = _AddComponentToTree(comp)
#		if item != null:
#			_comp_tree.deselect_all()
#			item.select(0)
#			component_selected.emit(_db_key, comp[&"uuid"])
	return res

func deselect() -> void:
	_comp_tree.deselect_all()
	selection_cleared.emit()


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_component_added(uuid : StringName) -> void:
	var db : ComponentDB = _db.get_ref()
	if db == null: return	
	if not db.has_component(uuid): return
	
	var comp : Dictionary = db.get_component(uuid)
	if comp.is_empty(): return
	
	_AddComponentToTree(comp)


func _on_component_removed(uuid : StringName) -> void:
	var root : TreeItem = _comp_tree.get_root()
	if root == null: return
	
	for coll in root.get_children():
		for child in coll.get_children():
			if child.get_metadata(0) == uuid:
				if child.is_selected(0):
					selection_cleared.emit()
				child.free()
				if coll.get_child_count() <= 0:
					coll.free()
				return

func _on_tree_item_selected():
	var item : TreeItem = _comp_tree.get_selected()
	if item != null and _db_key != &"":
		component_selected.emit(_db_key, item.get_metadata(0))

func _on_rem_component_confirmed(comp : Dictionary) -> void:
	if comp.is_empty(): return
	var db : ComponentDB = _db.get_ref()
	if db == null: return
	
	var res : int = db.remove_component(comp[&"uuid"])
	if res != OK:
		match res:
			ERR_LOCKED:
				_DisplayConfirmDialog("Cannot remove component. Database is locked.")
			ERR_DOES_NOT_EXIST:
				_DisplayConfirmDialog("Failed to find component within active database!")


func _on_move_ccomponent_pressed():
	if _db_key != &"" and _held_component[&"db_key"] != _db_key:
		var odb : ComponentDB = CCDB.get_database_by_key(_held_component[&"db_key"])
		if odb != null:
			var cmp : Dictionary = odb.get_component(_held_component[&"uuid"], true)
			if not cmp.is_empty() and _db.get_ref() != null:
				var res : int = _db.get_ref().add_component(cmp)
				if res != OK:
					_DisplayConfirmDialog("Failed to move component. Error adding component to database. Error code %d"%[res])
					return
				res = odb.remove_component(_held_component[&"uuid"])
				if res != OK:
					_DisplayConfirmDialog("Failed to move component. Error removing component from database. Error code %d"%[res])
	_ClearHeldComponent.call_deferred()


func _on_tool_id_pressed(id : int) -> void:
	match id:
		TOOL_ADD:
			if _db.get_ref() != null:
				new_component_requested.emit()
		TOOL_REMOVE:
			_RemoveComponent()
		TOOL_DUPLICATE:
			_DuplicateComponent()
		TOOL_HOLD:
			_HoldComponent()



