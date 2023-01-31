@tool
extends Control


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var max_value : int = 0 :						set = set_max_value
@export var min_value : int = 0 :						set = set_min_value
@export_range(1, 0x7F) var default_entry : int = 1 :	set = set_default_entry
@export var editable : bool = true


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _entries : Array = [1]
var _idx : int = 0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _size_label : Label = $VBC/Size/Label
@onready var _size_slider : HSlider = $VBC/Size/HSlider
@onready var _component_layout : ComponentLayout = $VBC/CmpLayout/ComponentLayout

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_min_value(v : int) -> void:
	if v >= 0 and v <= max_value:
		var grow_entries : bool = v < min_value
		min_value = v
		var rng : int = max_value - min_value
		if grow_entries:
			var count : int = rng - _entries.size()
			for _i in range(count):
				_entries.push_front(default_entry)
			_idx += count
		else:
			var count : int = _entries.size() - rng
			for _i in range(count):
				_entries.pop_front()
			_idx = max(0, _idx - count)
		_UpdateSizeSlider()

func set_max_value(v : int) -> void:
	if v >= 0 and v >= min_value:
		var grow_entries : bool = v > max_value
		max_value = v
		var rng : int = max_value - min_value
		if grow_entries:
			var count : int = rng - _entries.size()
			for _i in range(count):
				_entries.push_back(default_entry)
		else:
			var count : int = _entries.size() - rng
			for _i in range(count):
				_entries.pop_back()
			_idx = min(rng - 1, _idx)
		_UpdateSizeSlider()

func set_default_entry(d : int) -> void:
	if d > 0 and d <= 0x7F:
		default_entry = d

func set_editable(e : bool) -> void:
	if e != editable:
		editable = e
		if _size_slider != null:
			_size_slider.editable = editable
		if _component_layout != null:
			_component_layout.disabled = not editable

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_component_layout.selected_bits_changed.connect(_on_selected_bits_changed)
	_size_slider.value_changed.connect(_on_size_value_changed)
	set_range(min_value, max_value)
	_size_slider.editable = editable
	_component_layout.disabled = not editable


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateSizeSlider() -> void:
	if _size_slider != null and _size_label != null:
		_size_slider.max_value = _entries.size() - 1
		_size_slider.value = _idx
		_size_label.text = "%s"%[min_value + _idx]


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	for i in range(_entries.size()):
		_entries[i] = default_entry
	_component_layout.selected_bits = default_entry
	_idx = 0

func get_entries() -> Array[int]:
	return _entries.duplicate()

func set_entries(earr : Array[int]) -> void:
	if earr.size() != _entries.size():
		printerr("Entry list does not match range.")
		return
	for i in range(earr.size()):
		_entries[i] = earr[i] & 0x7F
	_component_layout.selected_bits = _entries[_idx]

func set_range(min_v : int, max_v : int, reset_index : bool = false) -> void:
	if min_v <= max_v:
		if min_v > max_value:
			max_value = max_v
			min_value = min_v
		else:
			min_value = min_v
			max_value = max_v
		if reset_index:
			_idx = 0
		_UpdateSizeSlider()

func set_range_vector(range_vec : Vector2i, reset_index : bool = false) -> void:
	set_range(range_vec.x, range_vec.y, reset_index)


func get_range_vector() -> Vector2i:
	return Vector2i(min_value, max_value)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_selected_bits_changed(bits : int) -> void:
	_entries[_idx] = bits

func _on_size_value_changed(value : float) -> void:
	_idx = int(value)
	_size_label.text = "%s"%[min_value + _idx]
	_component_layout.selected_bits = _entries[_idx]
