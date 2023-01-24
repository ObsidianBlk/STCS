@tool
extends Node

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ATTRIB_OBJECTS : Array = [
	preload("res://addons/Components/objects/Attrib_PowGen.gd")
]

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _attrib_handler : Dictionary = {}
var _attrib_schema : Dictionary = {}

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	for att in ATTRIB_OBJECTS:
		var atti = att.new()
		if atti.has_method("register"):
			atti.register()

# ------------------------------------------------------------------------------
# Semi-Public Methods
# ------------------------------------------------------------------------------
func Register_Attrib_Schema(attrib_name : StringName, Schema : Dictionary) -> void:
	if not attrib_name in _attrib_schema:
		_attrib_schema[attrib_name] = Schema

func Register_Attrib(attrib_name : StringName, attrib : RefCounted) -> void:
	if not attrib_name in _attrib_handler:
		_attrib_handler[attrib_name] = attrib

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func create_instance(db_name : StringName, uuid : StringName) -> Dictionary:
	var inst : Dictionary = {}
	var db : ComponentDB = CCDB.get_database_by_key(db_name)
	if db != null:
		var cmp : Dictionary = db.get_component(uuid)
		if not cmp.is_empty():
			inst = {
				&"db_name": db_name,
				&"uuid": uuid,
				&"sp": cmp[&"max_sp"],
				&"stress": 0,
				&"attributes": {}
			}
			if &"attributes" in cmp:
				for akey in cmp[&"Attributes"]:
					if akey in _attrib_handler and _attrib_handler[akey].has_instance_data():
						inst[&"attributes"][akey] = _attrib_handler[akey].get_instance_data(cmp)
	return inst

func exec(op : StringName, instance : Dictionary, default = null):
	pass
