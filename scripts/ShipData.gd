extends Resource
class_name ShipData

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
const SECTION_REGION_RADIUS : int = 4
const COMMAND_CENTER_COORD : Vector3i = Vector3i(2, 3, -5)
const DRIVE_CENTER_COORD : Vector3i = Vector3i(-3, -2, 5)

# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _designation : String = "DESIGNATION"
var _frame_size : int = 0
var _sections_seperated : bool = true

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
		&"grid":
			return _grid
	return null

func _set(property : StringName, value : Variant) -> bool:
	var success : bool = true
	match property:
		&"designation":
			if typeof(value) == TYPE_STRING:
				value = value.strip_edges()
				if not value.is_empty():
					_designation = value
				else : success = false
			else : success = false
		&"frame_size":
			if typeof(value) == TYPE_INT:
				if value >= 0:
					_frame_size = value
				else : success = false
			else : success = false
		
		&"sections_seperated":
			if typeof(value) == TYPE_BOOL:
				_sections_seperated = value
			else : success = false
		
		&"grid":
			if typeof(value) == TYPE_DICTIONARY:
				# TODO: Validate the dictionary is a valid grid
				_grid = value
			else : success = false
		_:
			success = false
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
			name = "grid",
			type = TYPE_DICTIONARY,
			usage = PROPERTY_USAGE_STORAGE
		}
	]
	
	return arr


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateGridSeperation() -> void:
	var line : Array = [
		Vector3i(-2, 2, 0),
		Vector3i(-1, 1, 0),
		Vector3i(0, 0, 0),
		Vector3i(1, -1, 0)
	]
	for v in line:
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

