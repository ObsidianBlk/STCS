extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal component_selected(db_name, uuid)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var frame_size : int = 0


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _filter_options : OptionButton = %FilterOptions
@onready var _component_list : ItemList = %ComponentList


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_frame_size(s : int) -> void:
	if s >= 0 and s != frame_size:
		frame_size = s
		if _filter_options == null: return
		if _filter_options.selected < 0: return
		_FillComponentItemList(_filter_options.get_item_text(_filter_options.selected))

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	for item in CSys.COMPONENT_TYPES:
		_filter_options.add_item(item)
	_filter_options.select(-1)
	_filter_options.item_selected.connect(_on_filter_option_item_selected)
	_component_list.item_selected.connect(_on_component_list_item_selected)


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _FillComponentItemList(type : StringName) -> void:
	_component_list.clear()
	for item in CCDB.get_component_list({&"type":type, &"size":frame_size}):
		var idx : int = _component_list.item_count
		_component_list.add_item(item[&"name"])
		_component_list.set_item_metadata(idx, item)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_filter_option_item_selected(idx : int) -> void:
	_FillComponentItemList(_filter_options.get_item_text(idx))

func _on_component_list_item_selected(idx : int) -> void:
	var item = _component_list.get_item_metadata(idx)
	if typeof(item) != TYPE_DICTIONARY: return
	component_selected.emit(item[&"db_name"], item[&"uuid"])
