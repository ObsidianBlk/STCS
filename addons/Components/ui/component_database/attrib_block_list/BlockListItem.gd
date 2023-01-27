@tool
extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal content_revealed(showing)
signal remove_requested()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ARROW_LEFT : Texture = preload("res://addons/Components/assets/icons/arrow_left.svg")
const ARROW_DOWN : Texture = preload("res://addons/Components/assets/icons/arrow_down.svg")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var title : String = "" :		set = set_title

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _content_control : Control = null
var _metadata = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _revealer_btn : Button = $Header/Layout/Revealer
@onready var _title_lbl : Label = $Header/Layout/Title
@onready var _content : Control = $Content

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_title(t : String) -> void:
	title = t
	if _title_lbl != null:
		_title_lbl.text = title

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_title_lbl.text = title
	if _content_control != null:
		_content.add_child(_content_control)
	_content.visible = false
	_revealer_btn.icon = ARROW_LEFT


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func add_content_control(ctrl : Control) -> void:
	if _content_control != null and _content != null:
		_content.remove_child(_content_control)
	
	_content_control = ctrl
	
	if _content != null and _content_control != null:
		_content.add_child(ctrl)

func get_content_control() -> Control:
	return _content_control

func get_metadata():
	return _metadata

func set_metadata(metadata) -> void:
	_metadata = metadata

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_revealer_pressed():
	_content.visible = not _content.visible
	_revealer_btn.icon = ARROW_DOWN if _content.visible else ARROW_LEFT


func _on_remove_pressed():
	remove_requested.emit()
