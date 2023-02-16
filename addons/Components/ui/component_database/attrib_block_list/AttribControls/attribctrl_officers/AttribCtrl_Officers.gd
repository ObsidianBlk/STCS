@tool
extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal data_updated(data)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANAME : StringName = &"officers"
const OFFICER_ENTRY : PackedScene = preload("res://addons/Components/ui/component_database/attrib_block_list/AttribControls/attribctrl_officers/OfficerEntry.tscn")

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _data : Dictionary = {}
var _next_id : int = 0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _list : Control = $Panel/ItemList/List


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if _data.is_empty():
		_data = _GetNewData()
	_BuildDataList()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetNewData() -> Dictionary:
	var ah : ComponentAttribute = CSys.get_attribute_handler(ANAME)
	if ah != null:
		return ah.get_attribute_data()
	return {}

func _ClearList() -> void:
	for child in _list.get_children():
		child.queue_free()
	_next_id = 0

func _AddItemToList(item_data : Dictionary = {}) -> void:
	var oe = OFFICER_ENTRY.instantiate()
	if oe == null: return
	
	oe.id = _next_id
	_next_id += 1
	
	if not item_data.is_empty():
		oe.set_data(item_data)
	
	oe.changed.connect(_on_entity_data_changed)
	oe.remove_requested.connect(_on_entity_remove_requested)
	_list.add_child(oe)

func _RemoveItemByID(item_id : int) -> void:
	for child in _list.get_children():
		if child.id == item_id:
			child.queue_free()
			data_updated.emit(get_data())
			break

func _BuildDataList() -> void:
	if _data.is_empty(): return
	for i in range(_data[&"list"].size()):
		_AddItemToList(_data[&"list"][i])

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	_ClearList()
	if not _data.is_empty():
		_data[&"list"].clear()


func set_data(data : Dictionary) -> void:
	if data.is_empty(): return
	
	var ah : ComponentAttribute = CSys.get_attribute_handler(ANAME)
	if ah == null: return
	var res : int = ah.validate_attribute_data(data)
	if res == OK:
		_ClearList()
		_data = data
		_BuildDataList()
	else:
		printerr("Attribute ", ANAME, " validation failure")

func get_data() -> Dictionary:
	var list : Array = []
	for child in _list.get_children():
		var data : Dictionary = child.get_data()
		list.append(data)#child.get_data())
	return {&"list":list}

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_add_item_pressed() -> void:
	_AddItemToList()
	data_updated.emit(get_data())

func _on_entity_data_changed(id : int) -> void:
	data_updated.emit(get_data())

func _on_entity_remove_requested(id : int) -> void:
	_RemoveItemByID(id)
