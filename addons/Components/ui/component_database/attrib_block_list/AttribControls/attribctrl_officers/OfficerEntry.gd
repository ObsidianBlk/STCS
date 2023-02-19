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
const RIGHT_ARROW_TEXTURE : Texture = preload("res://addons/Components/assets/icons/arrow_right.svg")

const RANKS : Array = [
	{"short":"Ens", "name":"Ensign", "ico":preload("res://addons/Components/assets/icons/ranks/rank_ensign.svg")},
	{"short":"LtJG", "name":"Lt Jr. Grade", "ico":preload("res://addons/Components/assets/icons/ranks/rank_ltjg.svg")},
	{"short":"Lt", "name":"Lieutenant", "ico":preload("res://addons/Components/assets/icons/ranks/rank_lieutenant.svg")},
	{"short":"LtC", "name":"LtCommander", "ico":preload("res://addons/Components/assets/icons/ranks/rank_ltcmdr.svg")},
	{"short":"Cdr", "name":"Commander", "ico":preload("res://addons/Components/assets/icons/ranks/rank_commander.svg")},
	{"short":"Cpt", "name":"Captain", "ico":preload("res://addons/Components/assets/icons/ranks/rank_captain.svg")}
]

const OFFICER_TYPES : Dictionary = {
	&"Any":Color.WHITE_SMOKE,
	&"Command":Color.ORANGE_RED,
	&"Medical":Color.SKY_BLUE,
	&"Science":Color.MEDIUM_SEA_GREEN,
	&"Operations":Color.ORCHID,
	&"Engineering":Color.TAN,
}

const COLOR_NON_COMMANDABLE : Color = Color.SLATE_GRAY
const COLOR_COMMANDABLE : Color = Color.GOLD

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

@onready var _collapse_btn : Button = $ItemCTRLs/Collapse
@onready var _commandable_ico : TextureRect = $InfoBar/Layout/Commandable_icon
@onready var _ranks_panel : PanelContainer = $InfoBar/Layout/Ranks
@onready var _min_rank_icon : TextureRect = $InfoBar/Layout/Ranks/HBC/MinRank
@onready var _max_rank_icon : TextureRect = $InfoBar/Layout/Ranks/HBC/MaxRank

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
	pop.clear()
	for i in range(RANKS.size()):
		pop.add_icon_item(RANKS[i]["ico"], RANKS[i]["name"], i)
		#pop.add_item(_RankIDToName(i), i)
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
	if id >= 0 and id < RANKS.size():
		return RANKS[id]["short"] if short else RANKS[id]["name"]
	return ""

func _UpdateInfoBar() -> void:
	_commandable_ico.modulate = COLOR_COMMANDABLE if _data[&"cmd"] == true else COLOR_NON_COMMANDABLE
	
	_min_rank_icon.texture = RANKS[_data[&"rank"].x]["ico"]

	_max_rank_icon.visible = (_data[&"rank"].y > _data[&"rank"].x and _data[&"rank"].y < RANKS.size())
	if _max_rank_icon.visible:
		_max_rank_icon.texture = RANKS[_data[&"rank"].y]["ico"]

	_ranks_panel.modulate = OFFICER_TYPES[_data[&"type"]]
	_info_bar_ctrl.visible = true

func _UpdateMaxRankList() -> void:
	var pop : PopupMenu = _max_rank_mbtn.get_popup()
	pop.clear()
	for i in range(RANKS.size()):
		if i > _data[&"rank"].x:
			pop.add_icon_item(RANKS[i]["ico"], RANKS[i]["name"], i)
			#pop.add_item(_RankIDToName(i), i)
	pop.add_item("None", RANKS.size())
	
	if _data[&"rank"].y >= RANKS.size() or _data[&"rank"].x >= _data[&"rank"].y:
		_max_rank_mbtn.text = "None"
		_max_rank_mbtn.icon = null
	else:
		_max_rank_mbtn.text = RANKS[_data[&"rank"].y]["name"]
		_max_rank_mbtn.icon = RANKS[_data[&"rank"].y]["ico"]


func _UpdateEditBlockValues() -> void:
	if _edit_block_ctrl == null: return

	var pop : PopupMenu = _officer_type_mbtn.get_popup()
	_officer_type_mbtn.text = "-"
	for idx in range(pop.item_count):
		if pop.get_item_text(idx) == _data[&"type"]:
			_officer_type_mbtn.text = _data[&"type"]
			break
	
	_min_rank_mbtn.text = RANKS[_data[&"rank"].x]["name"]
	_min_rank_mbtn.icon = RANKS[_data[&"rank"].x]["ico"]
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
	if _data[&"rank"].y <= _data[&"rank"].x:
		_data[&"rank"].y = OFFICER_TYPES.size()
	
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
	_min_rank_mbtn.icon = pop.get_item_icon(idx)
	_data[&"rank"].x = id
	_UpdateMaxRankList()
	changed.emit(id)

func _on_max_rank_id_pressed(id : int) -> void:
	var pop : PopupMenu = _max_rank_mbtn.get_popup()
	if _data[&"rank"].x >= id:
		_max_rank_mbtn.text = "None"
		_max_rank_mbtn.icon = null
		_data[&"rank"].y = _data[&"rank"].x
	else:
		var idx : int = pop.get_item_index(id)
		_max_rank_mbtn.text = pop.get_item_text(idx)
		_max_rank_mbtn.icon = pop.get_item_icon(idx)
		_data[&"rank"].y = id
	changed.emit(id)

func _on_captain_seat_toggled(button_pressed : bool) -> void:
	_data[&"cmd"] = button_pressed
	changed.emit(id)
