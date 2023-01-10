@tool
extends Control
class_name ComponentLayout

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------
const SQRT3 : float = sqrt(3)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var flat : bool = false :		set = set_flat

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _hexes : Array = []
var _hex_size : Vector2 = Vector2.ZERO

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_flat(f : bool) -> void:
	if f != flat:
		flat = f
		_CalculateHexes()
		queue_redraw()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_CalculateHexes()
	set_custom_minimum_size(_hex_size)

func _draw() -> void:
	var target_size : Vector2 = get_size()
	var hex_scale : Vector2 = Vector2.ZERO
	print("Trying to Draw")
	if _hex_size.x <= 0.0 or _hex_size.y <= 0.0:
		return
	if target_size.x <= 0.0 or target_size.y <= 0.0:
		return
	
	hex_scale = target_size / _hex_size
	print("Drawing to scale: ", hex_scale)
	var draw_hex : Callable = func(hex : PackedVector2Array):
		draw_polyline(hex, Color.YELLOW, 1.0, true)
	
	for hex in _hexes:
		draw_hex.call(hex)

func _gui_input(event : InputEvent) -> void:
	pass

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			pass # Mouse entered the area of this control.
		NOTIFICATION_MOUSE_EXIT:
			pass # Mouse exited the area of this control.
		NOTIFICATION_FOCUS_ENTER:
			pass # Control gained focus.
		NOTIFICATION_FOCUS_EXIT:
			pass # Control lost focus.
		NOTIFICATION_THEME_CHANGED:
			pass # Theme used to draw the control changed;
			# update and redraw is recommended if using a theme.
		NOTIFICATION_VISIBILITY_CHANGED:
			pass # Control became visible/invisible;
			# check new status with is_visible().
		NOTIFICATION_RESIZED:
			queue_redraw()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _HexToPoint(hex : Vector3i) -> Vector2:
	var x : float = 0.0
	var y : float = 0.0
	if hex.x + hex.y + hex.z == 0:
		if flat:
			x = 1.5 * hex.x
			y = ((SQRT3 * 0.5) * hex.x) + (SQRT3 * hex.z)
		else:
			x = (SQRT3 * hex.x) + ((SQRT3 * 0.5) * hex.z)
			y = 1.5 * hex.z
	return Vector2(x,y)

func _GetHexPoints(coord : Vector3i) -> PackedVector2Array:
	var points : Array = []
	var origin : Vector2 = _HexToPoint(coord)
	var point : Vector2 = Vector2.RIGHT if flat else Vector2.UP
	for i in range(6):
		points.append(origin + point.rotated(deg_to_rad(60.0 * i)))
	points.append(point)
	return PackedVector2Array(points)

func _CalculateHexes() -> void:
	_hexes.clear()
	var pos_min : Vector2 = Vector2.ZERO
	var pos_max : Vector2 = Vector2.ZERO
	_hexes.append(_GetHexPoints(Vector3i.ZERO))
	_hexes.append(_GetHexPoints(Vector3i(0, -1, 1)))
	_hexes.append(_GetHexPoints(Vector3i(-1, 0, 1)))
	_hexes.append(_GetHexPoints(Vector3i(-1, 1, 0)))
	_hexes.append(_GetHexPoints(Vector3i(0, 1, -1)))
	_hexes.append(_GetHexPoints(Vector3i(1, 0, -1)))
	_hexes.append(_GetHexPoints(Vector3i(1, -1, 0)))
	
	for hex in _hexes:
		for point in hex:
			if point.x < pos_min.x:
				pos_min.x = point.x
			elif point.x > pos_max.x:
				pos_max.x = point.x
			if point.y < pos_min.y:
				pos_min.y = point.y
			elif point.y > pos_max.y:
				pos_max.y = point.y
	_hex_size = pos_max - pos_min
