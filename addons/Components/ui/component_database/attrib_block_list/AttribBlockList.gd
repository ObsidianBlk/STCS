extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal attribute_added(attrib_name)
signal attribute_removed(attrib_name)
signal attribute_data_revealed(attrib_name, showing)
signal attribute_data_changed(attrib_name, data)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const BLOCKLISTITEM : PackedScene = preload("res://addons/Components/ui/component_database/attrib_block_list/BlockListItem.tscn")
const ATTRIB_EDITOR_CONTROL : Dictionary = {
	&"pow_gen": preload("res://addons/Components/ui/component_database/attrib_block_list/AttribControls/attribctrl_powgen/AttribCtrl_PowGen.tscn"),
	
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _list : VBoxContainer = $Layout/AttribList/Scroll/List


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetAttributeItem(attrib_name : StringName) -> Control:
	for child in _list.get_children():
		if child.has_method("get_metadata"):
			var meta = child.get_metadata()
			if typeof(meta) == TYPE_STRING_NAME and meta == attrib_name:
				return child
	return null

func _AttributeItemExists(attrib_name : StringName) -> bool:
	return _GetAttributeItem(attrib_name) != null

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_available_attributes() -> Array:
	var alist : Array = []
	for attrib_name in ATTRIB_EDITOR_CONTROL.keys():
		if not _AttributeItemExists(attrib_name):
			alist.append(attrib_name)
	return alist

func get_assigned_attributes() -> Array:
	var alist : Array = []
	for child in _list.get_children():
		if child.has_method("get_metadata"):
			var meta = child.get_metadata()
			if typeof(meta) == TYPE_STRING_NAME:
				alist.append(meta)
	return alist


func add_attribute(attrib_name : StringName) -> void:
	if attrib_name in ATTRIB_EDITOR_CONTROL:
		if _AttributeItemExists(attrib_name): return
		var actrl : Control = ATTRIB_EDITOR_CONTROL[attrib_name].instantiate()
		var item : Control = BLOCKLISTITEM.instantiate()
		if actrl != null and item != null:
			if actrl.has_signal("data_updated"):
				actrl.data_updated.connect(_on_attrib_data_updated.bind(attrib_name))
			item.title = attrib_name
			item.add_content_control(actrl)
			item.set_metadata(attrib_name)
			_list.add_child(item)
			item.remove_requested.connect(remove_attribute.bind(attrib_name))
			item.content_revealed.connect(_on_item_content_revealed.bind(attrib_name))
			attribute_added.emit(attrib_name)


func remove_attribute(attrib_name : StringName) -> void:
	var item : Control = _GetAttributeItem(attrib_name)
	if item != null:
		_list.remove_child(item)
		item.queue_free()
		attribute_removed.emit(attrib_name)

func set_attribute_data(attrib_name : StringName, data : Dictionary) -> void:
	var item : Control = _GetAttributeItem(attrib_name)
	if item == null: return
	
	var ctrl : Control = item.get_content_control()
	if ctrl == null: return

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_item_content_revealed(showing : bool, attrib_name : StringName) -> void:
	attribute_data_revealed.emit(attrib_name, showing)

func _on_attrib_data_updated(data : Dictionary, attrib_name : StringName) -> void:
	attribute_data_changed.emit(attrib_name, data)
