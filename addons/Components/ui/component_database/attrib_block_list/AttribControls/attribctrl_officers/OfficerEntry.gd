@tool
extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal changed(id)
signal remove_requested(id)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DOWN_ARROW_TEXTURE : Texture = preload("res://addons/Components/assets/icons/arrow_down.svg")
const RIGHT_ARROW_TEXTURE : Texture = preload("res://addons/Components/assets/icons/arrow_left.svg")

const RANK_COUNT : int = 5

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var id : int = -1

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _data : Dictionary = {
	&"type":&"Any",
	&"rank":Vector2i(0,0),
	&"cmd":false
}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _info_bar_ctrl : Control = $InfoBar
@onready var _edit_block_ctrl : Control = $EditBlock


@onready var _collapse_btn : Button = $ItemCTRLs/Buttons/Collapse
@onready var _commandable_lbl : Label = $InfoBar/Layout/Commandable
@onready var _type_name_lbl : Label = $InfoBar/Layout/Type/TypeName
@onready var _rank_range_lbl : Label = $InfoBar/Layout/Rank/RankRange

@onready var _officer_type_mbtn : MenuButton = $EditBlock/Layout/OfficerType
@onready var _min_rank_mbtn : MenuButton = $EditBlock/Layout/MinRank
@onready var _max_rank_mbtn : MenuButton = $EditBlock/Layout/MaxRank
@onready var _captain_seat_check : CheckButton = $EditBlock/Layout/CaptainSeat


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	var pop : PopupMenu = _officer_type_mbtn.get_popup()
	if pop != null:
		pop.index_pressed.connect(_on_officer_type_index_pressed)
	
	pop = _min_rank_mbtn.get_popup()
	for i in range(0, 5):
		pop.add_item(_RankIDToName(i), i)
	if pop != null:
		pop.id_pressed.connect(_on_min_rank_id_pressed)
	
	pop = _max_rank_mbtn.get_popup()
	if pop != null:
		pop.id_pressed.connect(_on_max_rank_id_pressed)
	
	_edit_block_ctrl.visible = false
	_UpdateInfoBar()
	_UpdateEditBlockValues()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _RankIDToName(id : int, short : bool = false) -> String:
	match id:
		0: return "Ens" if short else "Ensign"
		1: return "Lt" if short else "Lieutenant"
		2: return "LtC" if short else "LtCommander"
		3: return "Cdr" if short else "Commander"
		4: return "Cpt" if short else "Captain"
	return ""

func _UpdateInfoBar() -> void:
	_commandable_lbl.text = "[ CMD ]" if _data[&"cmd"] == true else "[ Non-CMD ]"
	_rank_range_lbl.text = _RankIDToName(_data[&"rank"].x, true)
	if _data[&"rank"].y > _data[&"rank"].x:
		_rank_range_lbl.text += " to %s"%[_RankIDToName(_data[&"rank"].y, true)]
	_type_name_lbl.text = _data[&"type"]
	_info_bar_ctrl.visible = true

func _UpdateMaxRankList() -> void:
	var pop : PopupMenu = _max_rank_mbtn.get_popup()
	pop.clear()
	for i in range(RANK_COUNT):
		if i > _data[&"rank"].x:
			pop.add_item(_RankIDToName(i), i)
	pop.add_item("None", RANK_COUNT)
	
	if _data[&"rank"].x >= _data[&"rank"].y:
		_max_rank_mbtn.text = "None"
	else:
		_max_rank_mbtn.text = _RankIDToName(_data[&"rank"].y)


func _UpdateEditBlockValues() -> void:
	if _edit_block_ctrl == null: return

	var pop : PopupMenu = _officer_type_mbtn.get_popup()
	_officer_type_mbtn.text = "-"
	for idx in range(pop.item_count):
		if pop.get_item_text(idx) == _data[&"type"]:
			_officer_type_mbtn.text = _data[&"type"]
			break
	
	_min_rank_mbtn.text = _RankIDToName(_data[&"rank"].x)
	if _data[&"rank"].x > _data[&"rank"].y:
		_data[&"rank"].y = _data[&"rank"].x
	_UpdateMaxRankList()
	
	_captain_seat_check.button_pressed = _data[&"cmd"]

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_data(data : Dictionary) -> void:
	for key in _data.keys():
		if key in data:
			_data[key] = data[key]
	if _info_bar_ctrl != null:
		if _info_bar_ctrl.visible == true:
			_UpdateInfoBar()
	_UpdateEditBlockValues()

func get_data() -> Dictionary:
	return {
		&"type": _data[&"type"],
		&"rank": _data[&"rank"],
		&"cmd": _data[&"cmd"]
	}

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_collapse_pressed() -> void:
	if _info_bar_ctrl.visible:
		_info_bar_ctrl.visible = false
		_edit_block_ctrl.visible = true
		_collapse_btn.icon = DOWN_ARROW_TEXTURE
	else:
		_UpdateInfoBar()
		_edit_block_ctrl.visible = false
		_collapse_btn.icon = RIGHT_ARROW_TEXTURE

func _on_remove_pressed() -> void:
	remove_requested.emit(id)

func _on_officer_type_index_pressed(idx : int) -> void:
	var pop : PopupMenu = _officer_type_mbtn.get_popup()
	_data[&"type"] = StringName(pop.get_item_text(idx))
	_officer_type_mbtn.text = _data[&"type"]
	changed.emit(id)

func _on_min_rank_id_pressed(id : int) -> void:
	var pop : PopupMenu = _min_rank_mbtn.get_popup()
	var idx : int = pop.get_item_index(id)
	_min_rank_mbtn.text = pop.get_item_text(idx)
	_data[&"rank"].x = id
	_UpdateMaxRankList()
	changed.emit(id)

func _on_max_rank_id_pressed(id : int) -> void:
	var pop : PopupMenu = _max_rank_mbtn.get_popup()
	if _data[&"rank"].x >= id:
		_max_rank_mbtn.text = "None"
		_data[&"rank"].y = _data[&"rank"].x
	else:
		var idx : int = pop.get_item_index(id)
		_max_rank_mbtn.text = _RankIDToName(id)
		_data[&"rank"].y = id
	changed.emit(id)

func _on_captain_seat_toggled(button_pressed : bool) -> void:
	_data[&"cmd"] = button_pressed
	changed.emit(id)
