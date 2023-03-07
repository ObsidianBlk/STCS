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
const STRUCT_SCHEMA : Dictionary = {
	&"g":{&"req":true, &"type":TYPE_DICTIONARY, &"def":{
		&"!KEY_OF_TYPE_v3i":{
			&"type":TYPE_VECTOR3I,
			&"def":{
				&"req":true,
				&"type":TYPE_STRING_NAME,
				&"allow_empty":true
			}
		}
	}},
	&"c":{&"req":true, &"type":TYPE_DICTIONARY, &"def":{
		&"!KEY_OF_TYPE_sn":{
			&"type":TYPE_STRING_NAME,
			&"def":{
				&"type":TYPE_DICTIONARY,
#				&"def":{
#					&"instance":{
#						&"req":true,
#						&"type":TYPE_DICTIONARY
#					},
#					&"cells":{
#						&"req":true,
#						&"type":TYPE_ARRAY,
#						&"item":{
#							&"type":TYPE_VECTOR3I
#						}
#					}
#				}
			}
		}
	}}
}

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

var _struct : Dictionary = {
	&"g": {}, # Grid
	&"c": {}  # Components
}

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
		_struct.g[cell.qrs] = &""
	
	var hexDrive : HexCell = HexCell.Flat(DRIVE_CENTER_COORD)
	cells = hexDrive.get_region(SECTION_REGION_RADIUS)
	for cell in cells:
		_struct.g[cell.qrs] = &""


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
		&"struct":
			return _struct
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
		
		&"struct":
			if typeof(value) == TYPE_DICTIONARY:
				if _ValidateStructData(value) == OK:
					_struct = value
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
			name = "struct",
			type = TYPE_DICTIONARY,
			usage = PROPERTY_USAGE_STORAGE
		}
	]
	
	return arr


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ValidateStructData(struct : Dictionary) -> int:
	var res : int = DSV.verify(struct, STRUCT_SCHEMA)
	if res != OK:
		return res
	
	# Loop through the grid and validate that the component reference
	# matches an index in struct.c
	for coord in struct.g.keys():
		if struct.g[coord] == &"":
			continue
		if not (struct.g[coord] in struct.c):
			return ERR_DOES_NOT_EXIST
	
	# Loop through the component references...
	for cref in struct.c.keys():
		# Validate the component instance data
		res = CSys.validate_instance(_struct.c[cref].instance)
		if res != OK:
			return res
		
		# Loop through cells to verify they're in the grid and
		# the grid references the current component reference.
		for cell in _struct.c[cref].cells:
			if not cell in struct.g:
				return ERR_LINK_FAILED
			if struct.g[cell] != cref:
				return ERR_LINK_FAILED
	return OK

func _UpdateGridSeperation() -> void:
	for v in SECTION_GAP_COORDS:
		if v in _struct.g:
			if _sections_seperated:
				_struct.g.erase(v)
		else:
			_struct.g[v] = {}

func _CloneStructure() -> Dictionary:
	var nstruct : Dictionary = {
		&"g":{},
		&"c":{}
	}
	for cell in _struct.g.keys():
		nstruct.g[cell] = _struct.g[cell]
	
	for cref in _struct.c.keys():
		nstruct.c[cref] = {
			&"instance": CSys.duplicate_instance(_struct.c[cref].instance),
			&"cells": _struct.c[cref].cells.duplicate()
		}
	
	return nstruct


func _VariantToQRS(position : Variant) -> Vector3i:
	if position is HexCell:
		return position.qrs
	elif typeof(position) == TYPE_VECTOR3I:
		return position
	var hc : HexCell = HexCell.Flat(COMMAND_CENTER_COORD)
	hc = hc.get_neighbor(0, SECTION_REGION_RADIUS + 1)
	return hc.qrs

func _ComponentLayoutToPositionList(layout : int) -> Array:
	var positions : Array = []
	var hex : HexCell = HexCell.new()
	for idx in range(7):
		if layout & (1 << idx) != 0:
			if idx == 0:
				positions.append(hex.qrs)
			else:
				var qrs : Vector3i = hex.get_neighbor_qrs(idx - 1, 1)
				positions.append(qrs)
	return positions

func _GetComponentLayoutType(cdata : Dictionary) -> int:
	var component : Dictionary = CSys.get_component_from_instance(cdata)
	if not component.is_empty():
		return component[&"layout_type"]
	return -1

func _GetComponentStaticLayoutPositions(cdata : Dictionary) -> Array:
	var component : Dictionary = CSys.get_component_from_instance(cdata)
	if component.is_empty():
		return []
	if component[&"layout_type"] != CSys.COMPONENT_LAYOUT_TYPE.Static:
		return []
	if not (component[&"size_range"].x >= _frame_size and component[&"size_range"].y <= _frame_size):
		return []
	var idx : int = _frame_size - component[&"size_range"].x
	return _ComponentLayoutToPositionList(component[&"layout_list"][idx])

func _CanPlaceComponent(position : Vector3i, cdata : Dictionary) -> bool:
	var layout_type : int = _GetComponentLayoutType(cdata)
	match layout_type:
		CSys.COMPONENT_LAYOUT_TYPE.Static:
			var cposlist : Array = _GetComponentStaticLayoutPositions(cdata)
			if cposlist.size() <= 0:
				return false
			for cpos in cposlist:
				if (cpos + position) in _struct.g:
					if not _struct.g[(cpos + position)].is_empty():
						return false
		CSys.COMPONENT_LAYOUT_TYPE.Growable, CSys.COMPONENT_LAYOUT_TYPE.Cluster:
			return _struct.g[position].is_empty()
	return false

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clone() -> ShipData:
	var sd : ShipData = ShipData.new()
	sd.designation = _designation
	sd.frame_size = _frame_size
	sd.sections_seperated = _sections_seperated
	sd.struct = _CloneStructure()
	return sd

func get_component_positions() -> Array:
	return _struct.g.keys()

func can_place_component(position : Variant, cdata : Dictionary) -> bool:
	var pos : Vector3i = _VariantToQRS(position)
	
	if not pos in _struct.g:
		printerr("SHIP DATA ERROR: No component cell at position ", pos)
		return false
	if not cdata.is_empty():
		return false
	
	var res : int = CSys.validate_instance(cdata)
	if res != OK:
		printerr("SHIP DATA ERROR: Failed to validate component instance data.")
		return false
	
	return _CanPlaceComponent(pos, cdata)


func place_component(position : Variant, cdata : Dictionary) -> void:
	var pos : Vector3i = _VariantToQRS(position)
	
	if not pos in _struct.g:
		printerr("SHIP DATA ERROR: No component cell at position ", pos)
		return
	if cdata.is_empty():
		return
		
	var res : int = CSys.validate_instance(cdata)
	if res != OK:
		printerr("SHIP DATA ERROR: Failed to validate component instance data.")
		return
	
	if _CanPlaceComponent(pos, cdata):
		var layout_type = _GetComponentLayoutType(cdata)
		match layout_type:
			# TODO: Figure out how to "name" each component instance
			CSys.COMPONENT_LAYOUT_TYPE.Static:
				var plist : Array = _GetComponentStaticLayoutPositions(cdata)
				var cname : StringName = "%s:%s"%[cdata[&"uuid"], pos]
				_struct.c[cname] = cdata
				for p in plist:
					_struct.g[p + pos] = cname
				grid_changed.emit()
				# TODO: Store component into _struct.c, then store the component "name" in to
				#  all plist position in _struct.g
			CSys.COMPONENT_LAYOUT_TYPE.Growable:
				# TODO: After placing, need to handle grouping of adjacent growable components of
				#  the same type.
				pass
			CSys.COMPONENT_LAYOUT_TYPE.Cluster:
				var cname : StringName = "%s:%s"%[cdata[&"uuid"], pos]
				_struct.c[cname] = cdata
				_struct.g[pos] = cname
				grid_changed.emit()


func remove_component(position : Variant) -> void:
	var pos : Vector3i = _VariantToQRS(position)
	if not pos in _struct.g: return
	
	var cname : StringName = _struct.g[pos]
	if not cname in _struct.c:
		printerr("ERROR: Grid references non-existant component data.")
		return
	
	var cdata : Dictionary = _struct.c[cname]
	var layout_type = _GetComponentLayoutType(cdata)
	match layout_type:
		CSys.COMPONENT_LAYOUT_TYPE.Static:
			_struct.c.erase(cname)
			for key in _struct.g.keys():
				if _struct.g[key] == cname:
					_struct.g.erase(key)
			grid_changed.emit()
		CSys.COMPONENT_LAYOUT_TYPE.Growable:
			# REMINDER: Growables removed will need to handle possibility of being broken out into
		#  two different groups... THIS IS GOING TO SUUUUUUCK!
			pass
		CSys.COMPONENT_LAYOUT_TYPE.Cluster:
			_struct.c.erase(cname)
			_struct.g.erase(pos)
			grid_changed.emit()


func get_component(position : Variant) -> Dictionary:
	var pos : Vector3i = _VariantToQRS(position)
		
	if not pos in _struct.g:
		return {}
	if _struct.g[pos] in _struct.c:
		var cref : StringName = _struct.g[pos]
		return CSys.duplicate_instance(_struct.c[cref].instance)
	
	return {}

func get_position_unit_xy() -> Vector2i:
	return _position.to_point()

