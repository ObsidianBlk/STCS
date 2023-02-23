extends Resource
class_name ShipData

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal grid_changed()
signal position_changed()
signal component_modified(position)

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
const SECTION_REGION_RADIUS : int = 4
const COMMAND_CENTER_COORD : Vector3i = Vector3i(2, 3, -5)
const DRIVE_CENTER_COORD : Vector3i = Vector3i(-3, -2, 5)
const SECTION_GAP_COORDS : Array = [
	Vector3i(-2, 2, 0),
	Vector3i(-1, 1, 0),
	Vector3i(0, 0, 0),
	Vector3i(1, -1, 0)
]

# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _designation : String = "DESIGNATION"
var _frame_size : int = 0
var _sections_seperated : bool = true
var _position : HexCell = HexCell.new()

var _grid : Dictionary = {}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _init() -> void:
	var hexCMD : HexCell = HexCell.Flat(COMMAND_CENTER_COORD)
	var cells : Array = hexCMD.get_region(SECTION_REGION_RADIUS)
	for cell in cells:
		_grid[cell.qrs] = {}
	
	var hexDrive : HexCell = HexCell.Flat(DRIVE_CENTER_COORD)
	cells = hexDrive.get_region(SECTION_REGION_RADIUS)
	for cell in cells:
		_grid[cell.qrs] = {}


func _get(property : StringName):
	match property:
		&"designation":
			return _designation
		&"frame_size":
			return _frame_size
		&"sections_seperated":
			return _sections_seperated
		&"position_qrs":
			return _position.qrs
		&"position":
			return _position.clone()
		&"grid":
			return _grid
	return null


func _set(property : StringName, value : Variant) -> bool:
	var success : bool = false
	match property:
		&"designation":
			if typeof(value) == TYPE_STRING:
				value = value.strip_edges()
				if not value.is_empty():
					_designation = value
					success = true
		&"frame_size":
			if typeof(value) == TYPE_INT:
				if value >= 0:
					_frame_size = value
					success = true
		
		&"sections_seperated":
			if typeof(value) == TYPE_BOOL:
				_sections_seperated = value
				_UpdateGridSeperation()
				success = true
		
		&"position_qrs", &"position":
			if typeof(value) == TYPE_VECTOR3I:
				_position.qrs = value
				success = true
				position_changed.emit()
			elif value is HexCell:
				_position.qrs = value.qrs
				success = true
				position_changed.emit()
		
		&"grid":
			if typeof(value) == TYPE_DICTIONARY:
				if _ValidateGridData(value) == OK:
					_grid = value
					success = true
	return success


func _get_property_list() -> Array:
	var arr : Array = [
		{
			name="Ship Data",
			type=TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
		{
			name = "designation",
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "frame_size",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "sections_seperated",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "position_qrs",
			type = TYPE_VECTOR3I,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "grid",
			type = TYPE_DICTIONARY,
			usage = PROPERTY_USAGE_STORAGE
		}
	]
	
	return arr


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ValidateGridData(gdata : Dictionary) -> int:
	for coord in gdata:
		if typeof(coord) != TYPE_VECTOR3I:
			return ERR_INVALID_PARAMETER
		var res : int = CSys.validate_instance(gdata[coord])
		if res != OK:
			return res
	return OK


func _UpdateGridSeperation() -> void:
	for v in SECTION_GAP_COORDS:
		if v in _grid:
			if _sections_seperated:
				_grid.erase(v)
			else:
				_grid[v] = {}

func _CloneGrid() -> Dictionary:
	var ngrid : Dictionary = {}
	for idx in _grid.keys():
		if not _grid[idx].is_empty():
			# TODO: Shit myself if duplication fails.
			ngrid[idx] = CSys.duplicate_instance(_grid[idx])
		else:
			ngrid[idx] = {}
	return ngrid

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clone() -> ShipData:
	var sd : ShipData = ShipData.new()
	sd.designation = _designation
	sd.frame_size = _frame_size
	sd.sections_seperated = _sections_seperated
	sd.grid = _CloneGrid()
	return sd

func get_component_positions() -> Array:
	return _grid.keys()

func set_component(position : Variant, cdata : Dictionary) -> void:
	var pos : Vector3i = Vector3i.ZERO
	if position is HexCell:
		pos = position.qrs
	elif typeof(position) == TYPE_VECTOR3I:
		pos = position
	else:
		return
	
	if not pos in _grid:
		printerr("SHIP DATA ERROR: No component cell at position ", pos)
		return
	if not cdata.is_empty():
		var res : int = CSys.validate_instance(cdata)
		if res != OK:
			printerr("SHIP DATA ERROR: Failed to validate component instance data.")
			return
		# TODO: Come up with mechanism for multi-celled components being placed.
		# TODO 2: If using a cell reference system, growable and clusterable may benefit.
	_grid[pos] = cdata
	component_modified.emit(pos)

func get_component(position : Variant) -> Dictionary:
	var pos : Vector3i = Vector3i.ZERO
	if position is HexCell:
		pos = position.qrs
	elif typeof(position) == TYPE_VECTOR3I:
		pos = position
	else:
		return {}
		
	if not pos in _grid:
		return {}
	if not _grid[pos].is_empty():
		return CSys.duplicate_instance(_grid[pos])
	
	return {}

func get_position_unit_xy() -> Vector2i:
	return _position.to_point()

