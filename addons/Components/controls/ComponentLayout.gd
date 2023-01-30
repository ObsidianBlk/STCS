@tool
extends Control
class_name ComponentLayout

# -------------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------------
signal selected_bits_changed(bits_selected)

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------
const THEME_CLASS_NAME : StringName = &"ComponentLayout"
const SQRT3 : float = sqrt(3)
const ORIENTATION_POINTY : int = 0
const ORIENTATION_FLAT : int = 1
const DEFAULT_MIN_SIZE : Vector2 = Vector2(16, 16)
const MIN_ASPECT_SIZE : float = 6.0

const HEXCOORDS : Array = [
	Vector3i.ZERO,
	Vector3i(0, -1, 1),
	Vector3i(-1, 0, 1),
	Vector3i(-1, 1, 0),
	Vector3i(0, 1, -1),
	Vector3i(1, 0, -1),
	Vector3i(1, -1, 0),
]

const THEME_DEF : Dictionary = {
	&"constants":{
		&"orientation" : ORIENTATION_POINTY
	},
	&"colors":{
		&"normal": Color.SLATE_BLUE,
		&"hover": Color.ROYAL_BLUE,
		&"focus": Color.TURQUOISE,
		&"disabled": Color.WEB_GRAY,
		&"selected": Color.MEDIUM_TURQUOISE
	},
	&"styles":{
		&"panel": null,
		&"focus": null,
	}
}

# -------------------------------------------------------------------------
# "Export" Variables
# -------------------------------------------------------------------------
var _selected_bits : int = 0 :					set = set_selected_bits
var _disabled : bool = false :					set = set_disabled

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _hexes : Array = []
var _hex_size : Vector2 = Vector2.ZERO
var _selected_idx : int = -1

var _mouse_active : bool = false
var _focus_active : bool = false

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_selected_bits(b : int) -> void:
	b = b & 0x7F
	if b != _selected_bits:
		_selected_bits = b
		queue_redraw()
		selected_bits_changed.emit(_selected_bits)

func set_disabled(d : bool) -> void:
	if d != _disabled:
		_disabled = d
		queue_redraw()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	self.focus_mode = Control.FOCUS_ALL
	_CalculateHexes()
	#set_custom_minimum_size(_hex_size)

func _get_minimum_size() -> Vector2:
	if custom_minimum_size.x > 0.0 or custom_minimum_size.y > 0:
		return custom_minimum_size
	return DEFAULT_MIN_SIZE

func _draw() -> void:
	var target_size : Vector2 = get_size()
	if _hex_size.x <= 0.0 or _hex_size.y <= 0.0:
		return
	if target_size.x <= 0.0 or target_size.y <= 0.0:
		return
	
	var origin : Vector2 = Vector2.ZERO
	
	var style : StyleBox = _GetStyleBox(&"panel")
	if style != null:
		style.draw(self.get_canvas_item(), Rect2(Vector2.ZERO, target_size))
		if _focus_active:
			var fstyle : StyleBox = _GetStyleBox(&"focus")
			if fstyle != null:
				fstyle.draw(self.get_canvas_item(), Rect2(Vector2.ZERO, target_size))
		
		# Given we have a background panel, let's adjust out "target_size" for the hexes
		# to respect the panel content margines as best as possible
		var ntsx : float = target_size.x - (style.content_margin_left + style.content_margin_right)
		var ntsy : float = target_size.y - (style.content_margin_top + style.content_margin_bottom)
		if ntsx >= MIN_ASPECT_SIZE and ntsy >= MIN_ASPECT_SIZE:
			target_size = Vector2(ntsx, ntsy)
			origin = Vector2(style.content_margin_left, style.content_margin_top)
	
	var color : Color = _GetColor(&"normal")
	if _disabled:
		color = _GetColor(&"disabled")
	elif _focus_active:
		color = _GetColor(&"focus")
	var hex_scale : Transform2D = Transform2D(0.0, target_size/_hex_size, 0.0, Vector2.ZERO)
	var hex_position : Transform2D = Transform2D(0.0, -(origin + (target_size * 0.5)))
	
	for idx in range(_hexes.size()):
		if not _disabled and _selected_idx != idx:
			if _selected_bits & (1 << idx) > 0:
				var sel_colors : PackedColorArray = PackedColorArray([color,color,color,color,color,color,color])
				draw_polygon(_hexes[idx] * hex_scale * hex_position, sel_colors)
			else:
				draw_polyline(_hexes[idx] * hex_scale * hex_position, color, 1.0, true)
	
	if not _disabled and _selected_idx >= 0:
		color = _GetColor(&"hover")
		if _selected_bits & (1 << _selected_idx) > 0:
			var sel_colors : PackedColorArray = PackedColorArray([color,color,color,color,color,color,color])
			draw_polygon(_hexes[_selected_idx] * hex_scale * hex_position, sel_colors)
		else:
			draw_polyline(_hexes[_selected_idx] * hex_scale * hex_position, color, 1.0, true)

func _gui_input(event : InputEvent) -> void:
	if _mouse_active and event is InputEventMouse:
		if event is InputEventMouseMotion:
			_selected_idx = _MouseToHex()
			accept_event()
			queue_redraw()
		elif event is InputEventMouseButton and _selected_idx >= 0:
			if event.is_pressed() and not event.is_echo():
				if _selected_bits & (1 << _selected_idx) > 0:
					set_selected_bits(_selected_bits & ((~(1 << _selected_idx)) & 0x7F))
				else:
					set_selected_bits(_selected_bits | (1 << _selected_idx))
				accept_event()
				queue_redraw()
	elif _focus_active:
		if not event.is_echo():
			var proc : bool = false
			if event.is_action_pressed("ui_up"):
				_selected_idx = max(0, min(6, (_selected_idx + 1) % 7))
				proc = true
			if event.is_action_pressed("ui_down"):
				_selected_idx = 6 if _selected_idx - 1 < 0 else _selected_idx - 1
				proc = true
			if event.is_action_pressed("ui_left"):
				_selected_idx = max(0, min(6, (_selected_idx + 1) % 7))
				proc = true
			if event.is_action_pressed("ui_right"):
				_selected_idx = 6 if _selected_idx - 1 < 0 else _selected_idx - 1
				proc = true
			if _selected_idx >= 0:
				if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
					if _selected_bits & (1 << _selected_idx) > 0:
						set_selected_bits(_selected_bits & ((~(1 << _selected_idx)) & 0x7F))
					else:
						set_selected_bits(_selected_bits | (1 << _selected_idx))
					proc = true
				if event.is_action_pressed("ui_cancel"):
					set_selected_bits(_selected_bits & ((~(1 << _selected_idx)) & 0x7F))
					proc = true
			
			if proc:
				accept_event()
				queue_redraw()


func _notification(what : int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_mouse_active = true
		NOTIFICATION_MOUSE_EXIT:
			_mouse_active = false
		NOTIFICATION_FOCUS_ENTER:
			_focus_active = true
			queue_redraw()
		NOTIFICATION_FOCUS_EXIT:
			_focus_active = false
			queue_redraw()
		NOTIFICATION_THEME_CHANGED:
			queue_redraw()
		NOTIFICATION_VISIBILITY_CHANGED:
			if visible:
				queue_redraw()
		NOTIFICATION_RESIZED:
			queue_redraw()

func _get(property : StringName):
	var prop_split : Array = property.split("/")
	match prop_split[0]:
		&"disabled":
			return _disabled
		&"selected_bits":
			return _selected_bits
		&"custom_constants":
			if prop_split.size() == 2 and has_theme_constant_override(prop_split[1]):
				return get_theme_constant(prop_split[1])
		&"custom_colors":
			if prop_split.size() == 2 and has_theme_color_override(prop_split[1]):
				return get_theme_color(prop_split[1])
		&"custom_styles":
			if prop_split.size() == 2 and has_theme_stylebox_override(prop_split[1]):
				return get_theme_stylebox(prop_split[1])
	return null

func _set(property : StringName, value) -> bool:
	var success : bool = true
	var prop_split : Array = property.split("/")
	match prop_split[0]:
		&"disabled":
			if typeof(value) == TYPE_BOOL:
				set_disabled(value)
			else : success = false
		&"selected_bits":
			if typeof(value) == TYPE_INT:
				set_selected_bits(value)
			else : success = false
		&"custom_constants":
			if prop_split.size() == 2:
				if typeof(value) == TYPE_NIL:
					remove_theme_constant_override(prop_split[1])
					_CalculateHexes()
					queue_redraw()
				elif typeof(value) == TYPE_INT:
					add_theme_constant_override(prop_split[1], value)
					_CalculateHexes()
					queue_redraw()
				else : success = false
			else : success = false
		&"custom_colors":
			if prop_split.size() == 2:
				if typeof(value) == TYPE_NIL:
					remove_theme_color_override(prop_split[1])
					notify_property_list_changed()
					queue_redraw()
				elif typeof(value) == TYPE_COLOR:
					add_theme_color_override(prop_split[1], value)
					notify_property_list_changed()
					queue_redraw()
				else : success = false
			else : success = false
		&"custom_styles":
			if prop_split.size() == 2:
				if typeof(value) == TYPE_NIL:
					remove_theme_stylebox_override(prop_split[1])
					notify_property_list_changed()
					queue_redraw()
				elif typeof(value) == TYPE_OBJECT and value is StyleBox:
					add_theme_stylebox_override(prop_split[1], value)
					notify_property_list_changed()
					queue_redraw()
				else: success = false
			else: success = false
		_:
			success = false
	return success

func _get_property_list() -> Array:
	var arr : Array = [
		{
			name="Component Layout",
			type=TYPE_NIL,
			usage=PROPERTY_USAGE_CATEGORY
		},
		{
			name="selected_bits",
			type=TYPE_INT,
			hint=PROPERTY_HINT_FLAGS,
			hint_string="center,pos1,pos2,pos3,pos4,pos5,pos6",
			usage=PROPERTY_USAGE_DEFAULT
		},
		{
			name="disabled",
			type=TYPE_BOOL,
			usage=PROPERTY_USAGE_DEFAULT
		},
		{
			name="Theme Overrides",
			type=TYPE_NIL,
			usage=PROPERTY_USAGE_GROUP
		},
		{
			name="Constants",
			type=TYPE_NIL,
			hint_string="custom_constants/",
			usage=PROPERTY_USAGE_SUBGROUP
		}
	]
	for key in THEME_DEF[&"constants"].keys():
		arr.append({
			name="custom_constants/%s"%[key],
			type=TYPE_INT,
			usage= 12 if not has_theme_constant_override(key) else 30
		})
	arr.append({
		name="Colors",
		type=TYPE_NIL,
		hint_string="custom_colors/",
		usage=PROPERTY_USAGE_SUBGROUP
	})
	for key in THEME_DEF[&"colors"].keys():
		arr.append({
			name="custom_colors/%s"%[key],
			type=TYPE_COLOR,
			usage=12 if not has_theme_color_override(key) else 30
		})
	arr.append({
		name="Styles",
		type=TYPE_NIL,
		hint_string="custom_styles/",
		usage=PROPERTY_USAGE_SUBGROUP
	})
	for key in THEME_DEF[&"styles"].keys():
		arr.append({
			name="custom_styles/%s"%[key],
			type=TYPE_OBJECT,
			hint=PROPERTY_HINT_RESOURCE_TYPE,
			hint_string="StyleBox",
			usage=12 if not has_theme_stylebox_override(key) else 30
		})
	#print(arr)
	return arr

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetOrientation() -> int:
	if has_theme_constant_override(&"orientation") or has_theme_constant(&"orientation"):
		return get_theme_constant(&"orientation")
	if has_theme_constant(&"orientation", THEME_CLASS_NAME):
		return get_theme_constant(&"orientation", THEME_CLASS_NAME)
	return ORIENTATION_POINTY

func _GetColor(color_name : StringName) -> Color:
	if color_name in THEME_DEF[&"colors"]:
		if has_theme_color_override(color_name) or has_theme_color(color_name):
			return get_theme_color(color_name)
		if has_theme_color(color_name, THEME_CLASS_NAME):
			return get_theme_color(color_name, THEME_CLASS_NAME)
		return THEME_DEF[&"colors"][color_name]
	return Color.BLACK

func _GetStyleBox(stylebox_name : StringName) -> StyleBox:
	if stylebox_name in THEME_DEF[&"styles"]:
		if has_theme_stylebox_override(stylebox_name) or has_theme_stylebox(stylebox_name):
			return get_theme_stylebox(stylebox_name)
		if has_theme_stylebox(stylebox_name, THEME_CLASS_NAME):
			return get_theme_stylebox(stylebox_name, THEME_CLASS_NAME)
		return get_theme_stylebox(stylebox_name, "Tree")
	return null

func _HexToPoint(hex : Vector3i) -> Vector2:
	var x : float = 0.0
	var y : float = 0.0
	var orientation : int = _GetOrientation()
	if hex.x + hex.y + hex.z == 0:
		match orientation:
			ORIENTATION_FLAT:
				x = 1.5 * hex.x
				y = ((SQRT3 * 0.5) * hex.x) + (SQRT3 * hex.z)
			ORIENTATION_POINTY:
				x = (SQRT3 * hex.x) + ((SQRT3 * 0.5) * hex.z)
				y = 1.5 * hex.z
	return Vector2(x,y)

func _RoundHex(v : Vector3) -> Vector3i:
	var _q : float = round(v.x)
	var _r : float = round(v.z)
	var _s : float = round(v.y)
	
	var dq : float = abs(v.x - _q)
	var dr : float = abs(v.z - _r)
	var ds : float = abs(v.y - _s)
	
	if dq > dr and dq > ds:
		_q = -_r -_s
	elif dr > ds:
		_r = -_q -_s
	else:
		_s = -_q -_r
	
	return Vector3i(int(_q), int(_s), int(_r))

func _PointToHex(point : Vector2) -> Vector3i:
	var fq : float = 0.0
	var fr : float = 0.0
	var orientation : int = _GetOrientation()
	match orientation:
		ORIENTATION_POINTY:
			fq = ((SQRT3/3.0) * point.x) - ((1.0/3.0) * point.y)
			fr = (2.0/3.0) * point.y
		ORIENTATION_FLAT:
			fq = (2.0/3.0) * point.x
			fr = ((-1.0/3.0) * point.x) + ((SQRT3/3.0) * point.y)
	var fs : float = -fq -fr
	return _RoundHex(Vector3(fq, fs, fr))

func _MouseToHex() -> int:
	var target_size : Vector2 = get_size()
	if target_size.x > 0.0 and target_size.y > 0.0 and _hex_size.x > 0.0 and _hex_size.y > 0.0:
		var mouse_pos : Vector2 = get_local_mouse_position()
		mouse_pos -= target_size * 0.5
		mouse_pos *= _hex_size / target_size
		var coord : Vector3i = _PointToHex(mouse_pos)
		return HEXCOORDS.find(coord)
	return -1

func _GetHexPoints(coord : Vector3i) -> PackedVector2Array:
	var points : Array = []
	var origin : Vector2 = _HexToPoint(coord)
	var flat : bool = _GetOrientation() == ORIENTATION_FLAT
	var point : Vector2 = Vector2.RIGHT if flat else Vector2.UP
	for i in range(6):
		points.append(origin + point.rotated(deg_to_rad(60.0 * i)))
	points.append(origin + point)
	return PackedVector2Array(points)

func _CalculateHexes() -> void:
	_hexes.clear()
	var pos_min : Vector2 = Vector2.ZERO
	var pos_max : Vector2 = Vector2.ZERO
	for coord in HEXCOORDS:
		_hexes.append(_GetHexPoints(coord))
#	_hexes.append(_GetHexPoints(Vector3i(0, -1, 1)))
#	_hexes.append(_GetHexPoints(Vector3i(-1, 0, 1)))
#	_hexes.append(_GetHexPoints(Vector3i(-1, 1, 0)))
#	_hexes.append(_GetHexPoints(Vector3i(0, 1, -1)))
#	_hexes.append(_GetHexPoints(Vector3i(1, 0, -1)))
#	_hexes.append(_GetHexPoints(Vector3i(1, -1, 0)))
	
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

