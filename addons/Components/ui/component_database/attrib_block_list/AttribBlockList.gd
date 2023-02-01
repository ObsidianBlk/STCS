@tool
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
const ATTRIB_MENU_DEFAULT_TEXT : String = "Select an Attribute"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var editable : bool = true :			set = set_editable

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _active_attrib_choice : StringName = &""

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _list : VBoxContainer = $Layout/AttribList/Scroll/List
@onready var _attribmenubtn : MenuButton = $Layout/AvailableAttribs/AttribMenuBtn
@onready var _addattribbtn : Button = $Layout/AvailableAttribs/AddAttrib


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_editable(e : bool) -> void:
	editable = e
	if _attribmenubtn != null:
		_attribmenubtn.disabled = not editable
	if _addattribbtn != null:
		_addattribbtn.disabled = not editable

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	var mpop : PopupMenu = _attribmenubtn.get_popup()
	mpop.clear() # We're a tool. Make sure this list is empty!
	mpop.id_pressed.connect(_on_attrib_menu_id_pressed)
	for key in ATTRIB_EDITOR_CONTROL:
		mpop.add_item(String(key))
		mpop.set_item_metadata(-1, key)
	_attribmenubtn.disabled = not editable
	_addattribbtn.disabled = not editable

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

func _AddAttribToAvailable(attrib_name : StringName) -> void:
	if attrib_name in ATTRIB_EDITOR_CONTROL:
		var mpop : PopupMenu = _attribmenubtn.get_popup()
		mpop.add_item(String(attrib_name))
		mpop.set_item_metadata(-1, attrib_name)

func _RemoveAttribFromAvailable(attrib_name : StringName) -> void:
	var mpop : PopupMenu = _attribmenubtn.get_popup()
	for idx in range(mpop.item_count):
		if mpop.get_item_metadata(idx) == attrib_name:
			mpop.remove_item(idx)
			if _active_attrib_choice == attrib_name:
				_active_attrib_choice = &""
				_attribmenubtn.text = ATTRIB_MENU_DEFAULT_TEXT

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	var alist : Array = get_assigned_attributes()
	for attrib_name in alist:
		remove_attribute(attrib_name)

func get_assigned_attribute_count() -> int:
	return get_assigned_attributes().size()

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
			_RemoveAttribFromAvailable(attrib_name)
			attribute_added.emit(attrib_name)

func set_attribute_dictionary(adict : Dictionary, clear_existing : bool = false) -> void:
	if clear_existing:
		clear()
	for key in adict.keys():
		if typeof(key) == TYPE_STRING_NAME and typeof(adict[key]) == TYPE_DICTIONARY:
			add_attribute(key)
			set_attribute_data(key, adict[key])

func remove_attribute(attrib_name : StringName) -> void:
	var item : Control = _GetAttributeItem(attrib_name)
	if item != null:
		_list.remove_child(item)
		item.queue_free()
		_AddAttribToAvailable(attrib_name)
		attribute_removed.emit(attrib_name)

func set_attribute_data(attrib_name : StringName, data : Dictionary) -> void:
	var item : Control = _GetAttributeItem(attrib_name)
	if item == null: return
	
	var ctrl : Control = item.get_content_control()
	if ctrl == null: return
	
	ctrl.set_data(data)

func get_attribute_data(attrib_name : StringName) -> Dictionary:
	var item : Control = _GetAttributeItem(attrib_name)
	if item != null:
		var ctrl : Control = item.get_content_control()
		if ctrl != null:
			return ctrl.get_data()
	return {}

func get_attribute_dictionary() -> Dictionary:
	var attrib_dict : Dictionary = {}
	var attrib_list : Array = get_assigned_attributes()
	for attrib_name in attrib_list:
		var data : Dictionary = get_attribute_data(attrib_name)
		if not data.is_empty():
			attrib_dict[attrib_name] = data
	return attrib_dict

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_item_content_revealed(showing : bool, attrib_name : StringName) -> void:
	attribute_data_revealed.emit(attrib_name, showing)

func _on_attrib_data_updated(data : Dictionary, attrib_name : StringName) -> void:
	attribute_data_changed.emit(attrib_name, data)

func _on_attrib_menu_id_pressed(id : int) -> void:
	var mpop : PopupMenu = _attribmenubtn.get_popup()
	var idx : int = mpop.get_item_index(id)
	_attribmenubtn.text = mpop.get_item_text(idx)
	_active_attrib_choice = mpop.get_item_metadata(idx)

func _on_add_attrib_pressed():
	if _active_attrib_choice != &"":
		add_attribute(_active_attrib_choice)
