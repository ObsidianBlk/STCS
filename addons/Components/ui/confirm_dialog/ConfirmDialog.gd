@tool
extends PopupPanel


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal yes_pressed()
signal no_pressed()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var text : String = "" :				set = set_text
@export var ok_only : bool = false
@export var close_on_pressed : bool = true


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var label : Label = $Center/Layout/Label
@onready var yes_button : Button = $Center/Layout/Options/Yes
@onready var no_button : Button = $Center/Layout/Options/No

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_text(t : String) -> void:
	text = t
	if label != null:
		label.text = text

func set_ok_only(o : bool) -> void:
	ok_only = o
	_SetConfirmState()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	label.text = text
	_SetConfirmState()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _SetConfirmState() -> void:
	if yes_button != null and no_button != null:
		if ok_only:
			yes_button.text = "OK"
			no_button.visible = false
		else:
			yes_button.text = "Yes"
			no_button.visible = true

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_yes_pressed():
	yes_pressed.emit()
	if close_on_pressed:
		queue_free()

func _on_no_pressed():
	no_pressed.emit()
	if close_on_pressed:
		queue_free()
