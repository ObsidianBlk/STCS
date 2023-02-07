@tool
extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal data_updated(data)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANAME : StringName = &"pow_req"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _data : Dictionary = {}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _max_line_edit : LineEdit = $Max_LineEdit
@onready var _req_line_edit : LineEdit = $Req_LineEdit
@onready var _auto_check : CheckButton = $Auto_CheckButton

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if _data.is_empty():
		_data = _GetNewData()
	
	_max_line_edit.text_changed.connect(_on_text_changed.bind(&"max", _max_line_edit))
	_max_line_edit.text_submitted.connect(_on_text_submitted.bind(&"max", _max_line_edit))
	_req_line_edit.text_changed.connect(_on_text_changed.bind(&"req", _req_line_edit))
	_req_line_edit.text_submitted.connect(_on_text_submitted.bind(&"req", _req_line_edit))
	_auto_check.toggled.connect(_on_auto_btn_toggled)
	
	if _data.is_empty(): # Technically this should NEVER happen, but JIC
		_max_line_edit.editable = false
		_req_line_edit.editable = false
		_auto_check.disabled = true
	else:
		_max_line_edit.text = "%s"%_data[&"max"]
		_req_line_edit.text = "%s"%_data[&"req"]
		_auto_check.button_pressed = _data[&"auto"]

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetNewData() -> Dictionary:
	var ah : ComponentAttribute = CSys.get_attribute_handler(ANAME)
	if ah != null:
		return ah.get_attribute_data()
	return {}

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_data(data : Dictionary) -> void:
	if data.is_empty(): return

	var ah : ComponentAttribute = CSys.get_attribute_handler(ANAME)
	if ah == null: return
	var res : int = ah.validate_attribute_data(data)
	if res == OK:
		_data = data
		if _max_line_edit != null:
			_max_line_edit.editable = true
			_max_line_edit.text = "%s"%_data[&"max"]
		
		if _req_line_edit != null:
			_req_line_edit.editable = true
			_req_line_edit.text = "%s"%_data[&"req"]
		
		if _auto_check != null:
			_auto_check.disabled = false
			_auto_check.button_pressed = _data[&"auto"]

		data_updated.emit(_data)
	else:
		printerr("Attribute ", ANAME, " validation failure")

func get_data() -> Dictionary:
	return _data

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_text_changed(new_text : String, prop : StringName, ctrl : LineEdit) -> void:
	if new_text.is_valid_int():
		var val : int = new_text.to_int()
		_data[prop] = max(1 if prop == &"req" else 0, val)
		if prop == &"max":
			if _data[prop] < _data[&"req"]:
				_data[prop] = _data[&"req"]
		if _data[prop] != val:
			ctrl.text = "%s"%[_data[prop]]
	else:
		ctrl.text = "%s"%[_data[prop]]

func _on_text_submitted(new_text : String, prop : StringName, ctrl : LineEdit) -> void:
	_on_text_changed(new_text, prop, ctrl)
	data_updated.emit(_data)

func _on_auto_btn_toggled(btn_pressed : bool) -> void:
	_data[&"auto"] = btn_pressed
	data_updated.emit(_data)
