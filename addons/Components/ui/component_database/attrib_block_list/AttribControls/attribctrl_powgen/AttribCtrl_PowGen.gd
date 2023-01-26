@tool
extends Control

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal data_updated(data)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANAME : StringName = &"pow_gen"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _data : Dictionary = {}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _line : LineEdit = $LineEdit

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if _data.is_empty():
		_data = _GetNewData()
	if _data.is_empty(): # Technically this should NEVER happen, but JIC
		_line.editable = false
	else:
		_line.text = "%s"%_data[&"ppt"]

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetNewData() -> Dictionary:
	var ah : ComponentAttribute = CSys.get_attribute_handler(ANAME)
	if ah != null:
		_data = ah.get_attribute_data()
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
		if _line != null:
			_line.editable = true
			_line.text = "%s"%_data[&"ppt"]
		data_updated.emit(_data)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

func _on_text_changed(new_text : String) -> void:
	if new_text.is_valid_int():
		var val : int = new_text.to_int()
		_data[&"ppt"] = max(1, val)
		if _data[&"ppt"] != val:
			_line.text = "%s"%[_data[&"ppt"]]
	else:
		_line.text = "%s"%[_data[&"ppt"]]

func _on_line_edit_text_submitted(new_text):
	_on_text_changed(new_text)
	data_updated.emit(_data)
	
