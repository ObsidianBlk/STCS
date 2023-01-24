@tool
extends Node

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ATTRIB_OBJECTS : Array = [
	preload("res://addons/Components/objects/Attrib_PowGen.gd"),
	preload("res://addons/Components/objects/Attrib_PowReq.gd"),
	preload("res://addons/Components/objects/Attrib_PowBat.gd"),
	
]

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _attribs : Dictionary = {}

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	for att in ATTRIB_OBJECTS:
		var atti = att.new()
		if atti is ComponentAttribute:
			var aname : StringName = atti.get_name()
			if aname != &"" and not aname in _attribs:
				_attribs[aname] = atti
				atti.response.connect(_on_attribute_response)

# ------------------------------------------------------------------------------
# Semi-Public Methods
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func validate_attribute_data(attrib_name : StringName, data : Dictionary) -> int:
	if not attrib_name in _attribs:
		return ERR_DATABASE_CANT_READ
	return _attribs[attrib_name].validate_attribute_data(data)

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
					if akey in _attribs:
						var idat : Dictionary = _attribs[akey].get_instance_data(cmp)
						if not idat.is_empty():
							inst[&"attributes"][akey] = idat
	return inst

func exec(op : StringName, instance : Dictionary, default = null):
	pass

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
func _on_attribute_response(msg : Dictionary) -> void:
	pass


