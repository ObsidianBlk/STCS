extends Node2D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const BASE_SIZE : float = 20.0

const COMP_TYPE_DEF : Dictionary = {
	&"bridge":[]
}

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

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_ship_data(sd : ShipData) -> void:
	if sd != ship_data:
		# TODO: Disconnect any signals
		ship_data = sd
		# TODO: Connect any signals
		_grid_update_requested = true

func set_zoom(z : float) -> void:
	if z >= 0.1 and z <= 3.0 and z != zoom:
		zoom = z
		_grid_update_requested

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	# I'm cheating for now...
	var sd : ShipData = ShipData.new()
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

