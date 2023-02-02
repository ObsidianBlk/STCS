@tool
extends Control

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal store_data_requested(data)
signal data_canceled()

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _data : Dictionary = {}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var uuid_line_edit : LineEdit = %UUID_LineEdit
@onready var name_line_edit : LineEdit  = %Name_LineEdit
@onready var type_line_edit : LineEdit  = %Type_LineEdit
@onready var sp_line_edit : LineEdit  = %SP_LineEdit
@onready var absorp_line_edit : LineEdit  = %Absorp_LineEdit
@onready var bleed_line_edit : LineEdit  = %Bleed_LineEdit
@onready var stress_line_edit : LineEdit  = %Stress_LineEdit
@onready var min_size_line_edit : LineEdit  = %MinSize_LineEdit
@onready var max_size_line_edit : LineEdit  = %MaxSize_LineEdit
@onready var range_indicator_label : Label = %RangeIndicator
@onready var layout_type_dropdown : MenuButton = %LayoutType_Dropdown
@onready var attrib_block_list : Control = $Layout/BasicStats/AttribBlockList
@onready var layout_config : Control = $Layout/LimitsLayouts/LayoutConfig
@onready var cancel_btn : Button = $ButtonGroup/Cancel
@onready var save_btn : Button = $ButtonGroup/Save


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	name_line_edit.text_submitted.connect(_on_line_edit_text_submitted.bind(&"name", name_line_edit))
	name_line_edit.focus_exited.connect(_on_line_edit_focus_exited.bind(&"name", name_line_edit))
	
	sp_line_edit.text_submitted.connect(_on_line_edit_text_submitted.bind(&"max_sp", sp_line_edit))
	sp_line_edit.focus_exited.connect(_on_line_edit_focus_exited.bind(&"max_sp", sp_line_edit))
	
	absorp_line_edit.text_submitted.connect(_on_line_edit_text_submitted.bind(&"absorption", absorp_line_edit))
	absorp_line_edit.focus_exited.connect(_on_line_edit_focus_exited.bind(&"absorption", absorp_line_edit))
	
	bleed_line_edit.text_submitted.connect(_on_line_edit_text_submitted.bind(&"bleed", bleed_line_edit))
	bleed_line_edit.focus_exited.connect(_on_line_edit_focus_exited.bind(&"bleed", bleed_line_edit))
	
	stress_line_edit.text_submitted.connect(_on_line_edit_text_submitted.bind(&"max_stress", stress_line_edit))
	stress_line_edit.focus_exited.connect(_on_line_edit_focus_exited.bind(&"max_stress", stress_line_edit))
	
	min_size_line_edit.text_submitted.connect(_on_layout_range_line_edit_text_submitted.bind(true))
	min_size_line_edit.focus_exited.connect(_on_layout_range_line_edit_focus_exited.bind(true))
	
	max_size_line_edit.text_submitted.connect(_on_layout_range_line_edit_text_submitted.bind(false))
	max_size_line_edit.focus_exited.connect(_on_layout_range_line_edit_focus_exited.bind(false))
	
	#layout_config.set_range(0, 0, true)
	#layout_config.clear()
	#layout_config.editable = true
	
	layout_type_dropdown.text = "Static"
	var ltpop : PopupMenu = layout_type_dropdown.get_popup()
	ltpop.clear()
	ltpop.add_item("Cluster", CSys.COMPONENT_LAYOUT_TYPE.Cluster)
	ltpop.add_item("Growable", CSys.COMPONENT_LAYOUT_TYPE.Growable)
	ltpop.add_item("Static", CSys.COMPONENT_LAYOUT_TYPE.Static)
	ltpop.id_pressed.connect(_on_layout_type_id_pressed)
	
	clear()
	#_UpdateRangeIndicator()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _EnableControls(enable : bool = true) -> void:
	#uuid_line_edit.editable = enable
	name_line_edit.editable = enable
	type_line_edit.editable = enable
	sp_line_edit.editable = enable
	absorp_line_edit.editable = enable
	bleed_line_edit.editable = enable
	stress_line_edit.editable = enable
	min_size_line_edit.editable = enable
	max_size_line_edit.editable = enable
	layout_type_dropdown.disabled = not enable
	attrib_block_list.editable = enable
	
	cancel_btn.disabled = not enable
	save_btn.disabled = not enable


func _UpdateLayoutConfigRange() -> void:
	var close_layout : bool = _data.is_empty() or _data[&"layout_type"] != CSys.COMPONENT_LAYOUT_TYPE.Static
	if close_layout:
		layout_config.editable = true
		layout_config.set_range(0, 0, true)
		layout_config.clear()
		layout_config.editable = false
	else:
		if _data[&"size_range"].x > _data[&"size_range"].y:
			layout_config.editable = false
		else:
			layout_config.editable = true
			layout_config.set_range_vector(_data[&"size_range"])

func _UpdateRangeIndicator() -> void:
	if _data.is_empty():
		range_indicator_label.text = "[ N/A ]"
		range_indicator_label.self_modulate = Color.WHITE
	elif _data[&"size_range"].x <= _data[&"size_range"].y:
		range_indicator_label.text = "[ VALID ]"
		range_indicator_label.self_modulate = Color.GREEN
	else:
		range_indicator_label.text = "[ INVALID ]"
		range_indicator_label.self_modulate = Color.RED


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	_data = {}
	uuid_line_edit.clear()
	name_line_edit.clear()
	type_line_edit.clear()
	sp_line_edit.clear()
	absorp_line_edit.clear()
	bleed_line_edit.clear()
	stress_line_edit.clear()
	min_size_line_edit.clear()
	min_size_line_edit.text = "0"
	max_size_line_edit.clear()
	max_size_line_edit.text = "0"
	layout_type_dropdown.text = "Static"
	attrib_block_list.clear()
	_UpdateRangeIndicator()
	_UpdateLayoutConfigRange()
	_EnableControls(false)

func create_new_record() -> void:
	# TODO: This method may be unneeded. There's no reason this couldn't be handled
	# outside this node.
	var new_comp : Dictionary = CSys.create_component_data()
	set_record(new_comp)

func set_record(crecord : Dictionary) -> void:
	# NOTE: For now, assume <crecord> is a valid component dictionary.
	_EnableControls(true)
	_data = crecord
	uuid_line_edit.text = _data[&"uuid"]
	name_line_edit.text = _data[&"name"]
	type_line_edit.text = _data[&"type"]
	sp_line_edit.text = "%s"%[_data[&"max_sp"]]
	absorp_line_edit.text = "%s"%[_data[&"absorption"]]
	bleed_line_edit.text = "%s"%[_data[&"bleed"]]
	stress_line_edit.text = "%s"%[_data[&"max_stress"]]
	min_size_line_edit.text = "%s"%[_data[&"size_range"].x]
	max_size_line_edit.text = "%s"%[_data[&"size_range"].y]
	_UpdateRangeIndicator()
	layout_config.editable = true
	if _data[&"layout_type"] == CSys.COMPONENT_LAYOUT_TYPE.Static:
		layout_config.set_range_vector(_data[&"size_range"])
		layout_config.set_entries(_data[&"layout_list"])
	else:
		layout_config.set_range_vector(Vector2i.ZERO)
		layout_config.clear()
		layout_config.editable = false
	
	attrib_block_list.clear()
	if &"attributes" in _data:
		attrib_block_list.set_attribute_dictionary(_data[&"attributes"], true)

func get_record_uuid() -> StringName:
	if _data.is_empty():
		return &""
	return _data[&"uuid"]

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_line_edit_focus_exited(val_name : StringName, lenode : LineEdit) -> void:
	_on_line_edit_text_submitted(lenode.text, val_name, lenode)

func _on_line_edit_text_submitted(new_text : String, val_name : StringName, lenode : LineEdit) -> void:
	if not val_name in _data: return
	
	if typeof(_data[val_name]) == TYPE_INT:
		var reset : bool = true
		if new_text.is_valid_int():
			var val : int = new_text.to_int()
			if val >= 0:
				_data[val_name] = val
				reset = false
		if reset:
			lenode.text = "%s"%[_data[val_name]]
	else:
		_data[val_name] = new_text

func _on_layout_range_line_edit_focus_exited(is_min : bool) -> void:
	if is_min:
		_on_layout_range_line_edit_text_submitted(min_size_line_edit.text, is_min)
	else:
		_on_layout_range_line_edit_text_submitted(max_size_line_edit.text, is_min)

func _on_layout_range_line_edit_text_submitted(new_text : String, is_min : bool) -> void:
	if _data.is_empty(): return
	
	var reset : bool = true
	if new_text.is_valid_int():
		var val : int = new_text.to_int()
		if val >= 0:
			if is_min:
				_data[&"size_range"].x = val
			else:
				_data[&"size_range"].y = val
			reset = false	
	if reset:
		if is_min:
			min_size_line_edit.text = "%s"%[_data[&"size_range"].x]
		else:
			max_size_line_edit.text = "%s"%[_data[&"size_range"].y]

	_UpdateRangeIndicator()
	_UpdateLayoutConfigRange()
	if _data[&"size_range"].x > _data[&"size_range"].y:
		pass
		# TODO: Also display an icon warning of a range conflict.
	else:
		pass

func _on_layout_type_id_pressed(id : int) -> void:
	if _data.is_empty(): return
	var id_valid : bool = true
	match id:
		CSys.COMPONENT_LAYOUT_TYPE.Cluster:
			layout_type_dropdown.text = "Cluster"
		CSys.COMPONENT_LAYOUT_TYPE.Growable:
			layout_type_dropdown.text = "Growable"
		CSys.COMPONENT_LAYOUT_TYPE.Static:
			layout_type_dropdown.text = "Static"
		_:
			id_valid = false
	if id_valid:
		_data[&"layout_type"] = id
	_UpdateLayoutConfigRange()

func _on_cancel_pressed():
	data_canceled.emit()

func _on_save_pressed():
	if not _data.is_empty():
		if attrib_block_list.get_assigned_attribute_count() > 0:
			_data[&"attributes"] = attrib_block_list.get_attribute_dictionary()
		if _data[&"layout_type"] == CSys.COMPONENT_LAYOUT_TYPE.Static:
			_data[&"layout_list"] = layout_config.get_entries()
		store_data_requested.emit(_data)
