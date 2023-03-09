extends Node2D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const BASE_SIZE : float = 20.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var ship_data : ShipData = null
@export_range(0.1,  5.0) var zoom : float = 1.0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _grid_update_requested : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var grid_container : Node2D = $GridContainer
@onready var component_list : Control = %ShipYardComponentList
@onready var cursor : Node2D = %Cursor

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_ship_data(sd : ShipData) -> void:
	if sd != ship_data:
		# TODO: Disconnect any signals
		ship_data = sd
		# TODO: Connect any signals
		if component_list != null:
			component_list.frame_size = ship_data.frame_size
		_grid_update_requested = true

func set_zoom(z : float) -> void:
	if z >= 0.1 and z <= 3.0 and z != zoom:
		zoom = z
		_grid_update_requested

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	component_list.component_selected.connect(_on_component_selected)
	
	# I'm cheating for now...
	var sd : ShipData = ShipData.new()
	sd.frame_size = 1
	sd.sections_seperated = false
	set_ship_data(sd)
	#_grid_update_requested = true

func _process(_delta : float) -> void:
	if grid_container != null and _grid_update_requested:
		_grid_update_requested = false
		_UpdateHexGrid()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

func _ClearHexes() -> void:
	for child in grid_container.get_children():
		if is_instance_of(child, Hex):
			child.queue_free()

func _UpdateHexGrid() -> void:
	if ship_data == null:
		_ClearHexes()
		return
	
	var comp_spaces : Array = ship_data.get_component_positions()
	var handled : Array = []
	
	for child in grid_container.get_children():
		if is_instance_of(child, Hex):
			var qrs : Vector2i = child.get_qrs_position()
			if not comp_spaces.has(qrs):
				child.queue_free()
			else:
				child.size = BASE_SIZE * zoom
				child.set_qrs_position(qrs)
				# child.set_hex_style(EVEN_HEX_STYLE if i % 2 == 0 else ODD_HEX_STYLE)
					
			handled.append(qrs)
	
	for qrs in comp_spaces:
		if not handled.has(qrs):
			var hex : Hex = Hex.new()
			hex.size = BASE_SIZE * zoom
			# hex.set_hex_style(EVEN_HEX_STYLE if i % 2 == 0 else ODD_HEX_STYLE)
			
			grid_container.add_child(hex)
			hex.set_qrs_position(qrs)

func _UpdateCursor(db_name : StringName, uuid : StringName) -> void:
	if ship_data == null: return
	
	for child in cursor.get_children():
		if is_instance_of(child, Hex):
			child.queue_free()
	
	var component : Dictionary = CCDB.get_component(db_name, uuid)
	if component.is_empty(): return
	
	var layout : int = CSys.get_component_layout(component, ship_data.frame_size)
	if layout <= 0: return
	
	var coord : HexCell = HexCell.new()
	for i in range(7):
		if layout & (1 << i) == 0: continue
		var hex : Hex = Hex.new()
		hex.size = BASE_SIZE * zoom
		cursor.add_child(hex)
		var ncoord : HexCell = coord if i == 0 else coord.get_neighbor(i-1, 1)
		hex.set_qrs_position(ncoord.qrs)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_component_selected(db_name : StringName, uuid : StringName) -> void:
	print("Selected: ", db_name, "->", uuid)
	_UpdateCursor(db_name, uuid)
