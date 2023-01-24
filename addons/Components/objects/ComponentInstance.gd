extends Resource
class_name ComponentInstance


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const INSTANCE_SCHEMA = {
	&"db_name": {&"req" : true, &"type" : TYPE_STRING_NAME},
	&"uuid": {&"req" : true, &"type" : TYPE_STRING_NAME},
	&"sp": {&"req" : true, &"type" : TYPE_INT},
	&"stress": {&"req" : true, &"type" : TYPE_INT},
	&"attributes": {&"req" : false, &"type" : TYPE_DICTIONARY}
}

# ------------------------------------------------------------------------------
# "Export" Variables
# ------------------------------------------------------------------------------
var _inst : Dictionary = {}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _db : WeakRef = weakref(null)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _get(property : StringName):
	match property:
		&"inst":
			return _inst
		_:
			if is_valid():
				var cmp : Dictionary = _db.get_component(_inst[&"uuid"])
				if property in cmp:
					return cmp[property]
				
				match property:
					&"sp":
						return _inst[&"sp"]
					&"stress":
						return _inst[&"stress"]
	return null

func _set(property : StringName, value) -> bool:
	if property == &"inst":
		if typeof(value) == TYPE_DICTIONARY:
			return _VerifyAndStoreInstance(value) == OK
	elif is_valid():
		var cmp : Dictionary = _db.get_component(_inst[&"uuid"])
		match property:
			&"sp":
				if typeof(value) == TYPE_INT:
					_inst[property] = min(cmp[&"max_sp"], value)
					return true
			&"stress":
				if typeof(value) == TYPE_INT:
					_inst[property] = min(cmp[&"max_stress"], value)
					return true
	return false

func _get_property_list() -> Array:
	return [
		{
			name="inst",
			type=TYPE_DICTIONARY,
			usage=PROPERTY_USAGE_STORAGE
		}
	]


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _VerifyAndStoreInstance(inst : Dictionary) -> int:
	var res : int = DSV.verify(inst, INSTANCE_SCHEMA)
	if res != OK:
		return res
	var db : ComponentDB = CCDB.get_database_by_key(inst[&"db_name"])
	if db == null:
		return ERR_DATABASE_CANT_READ
	if not db.has_component(inst[&"uuid"]):
		return ERR_CANT_ACQUIRE_RESOURCE
	_inst = inst
	_db = weakref(db)
	return OK

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func is_valid() -> bool:
	return not _inst.is_empty() and _db.get_ref() != null

