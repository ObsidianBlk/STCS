extends Control

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal store_data_requested(data)

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
@onready var layout_type_dropdown : MenuButton = %LayoutType_Dropdown
@onready var attrib_block_list : Control = $BasicStats/AttribBlockList
@onready var layout_config : Control = $LimitsLayouts/LayoutConfig

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	pass

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	pass

func create_new_record() -> void:
	# TODO: This method may be unneeded. There's no reason this couldn't be handled
	# outside this node.
	var new_comp : Dictionary = CSys.create_component_data()
	set_record(new_comp)

func set_record(crecord : Dictionary) -> void:
	# NOTE: For now, assume <crecord> is a valid component dictionary.
	_data = crecord


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
