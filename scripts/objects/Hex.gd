@tool
extends Node2D
class_name Hex

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const RAD_60 : float = deg_to_rad(60.0)
const STYLE_SCHEMA : Dictionary = {
	&"pointy":{&"req":false, &"type":TYPE_BOOL},
	&"size":{&"req":false, &"type":TYPE_FLOAT, &"min":0.01},
	&"line_thickness":{&"req":false, &"type":TYPE_FLOAT, &"min":0.0},
	&"line_color":{&"req":false, &"type":TYPE_COLOR},
	&"fill":{&"req":false, &"type":TYPE_BOOL},
	&"fill_color":{&"req":false, &"type":TYPE_COLOR},
	&"anti_aliased":{&"req":false, &"type":TYPE_BOOL}
}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var pointy : bool = false :					set = set_pointy
@export var size : float = 1.0 :					set = set_size
@export var line_thickness : float = 1.0 :			set = set_line_thickness
@export var line_color : Color = Color.WHITE :		set = set_line_color
@export var fill : bool = false :					set = set_fill
@export var fill_color : Color = Color.YELLOW :		set = set_fill_color
@export var anti_aliased : bool = false :			set = set_anti_aliased


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_pointy(p : bool) -> void:
	if p != pointy:
		pointy = p
		queue_redraw()

func set_size(s : float) -> void:
	if s > 0.0 and s != size:
		size = s
		queue_redraw()

func set_line_thickness(l : float) -> void:
	if l >= 0.0 and l != line_thickness:
		line_thickness = l
		queue_redraw()

func set_line_color(c : Color) -> void:
	if c != line_color:
		line_color = c
		queue_redraw()

func set_fill(f : bool) -> void:
	if f != fill:
		fill = f
		queue_redraw()

func set_fill_color(c : Color) -> void:
	if c != fill_color:
		fill_color = c
		queue_redraw()

func set_anti_aliased(aa : bool) -> void:
	if aa != anti_aliased:
		anti_aliased = aa
		queue_redraw()


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var point : Vector2 = Vector2(0, -size) if pointy else Vector2(-size, 0)
	var points : Array = [point]
	for i in range(1, 6):
		var rad = RAD_60 * i
		var npoint : Vector2 = point.rotated(rad)
		points.append(npoint)
	
	if fill:
		draw_colored_polygon(PackedVector2Array(points), fill_color)
	
	if line_thickness > 0.0:
		points.append(point)
		draw_polyline(PackedVector2Array(points), line_color, line_thickness, anti_aliased)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_hex_style(style_definition : Dictionary) -> void:
	if DSV.verify(style_definition, STYLE_SCHEMA) == OK:
		if &"pointy" in style_definition:
			pointy = style_definition[&"pointy"]
		if &"size" in style_definition:
			size = style_definition[&"size"]
		if &"line_thickness" in style_definition:
			line_thickness = style_definition[&"line_thickness"]
		if &"line_color" in style_definition:
			line_color = style_definition[&"line_color"]
		if &"fill" in style_definition:
			fill = style_definition[&"fill"]
		if &"fill_color" in style_definition:
			fill_color = style_definition[&"fill_color"]
		if &"anti_aliased" in style_definition:
			anti_aliased = style_definition[&"anti_aliased"]

func set_hex_position(hex : HexCell) -> void:
	var pos : Vector2 = hex.to_point() * size
	position = pos

func set_qrs_position(qrs : Vector3i) -> void:
	set_hex_position(HexCell.new(qrs, false, HexCell.ORIENTATION.Pointy if pointy else HexCell.ORIENTATION.Flat))

func get_hex_position() -> HexCell:
	if pointy:
		return HexCell.Pointy(position, true)
	return HexCell.Flat(position, true)

func get_qrs_position() -> Vector2i:
	var hex = get_hex_position()
	return hex.qrs

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------


