@tool
extends PopupPanel

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal dialog_canceled()
signal dialog_accepted(info)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var label_text : String = "" : 			set = set_label_text

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var label_node : Label = $Container/Layout/Label
@onready var line_node : LineEdit = $Container/Layout/LineEdit

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_label_text(t : String) -> void:
	label_text = t
	if label_node:
		label_node.text = label_text

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_label_text(label_text)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _Kill() -> void:
	hide()
	queue_free()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

func _on_accept_pressed() -> void:
	_on_line_edit_text_submitted(line_node.text)

func _on_cancel_pressed():
	dialog_canceled.emit()
	_Kill()

func _on_line_edit_text_submitted(new_text : String) -> void:
	dialog_accepted.emit(new_text)
	_Kill()
