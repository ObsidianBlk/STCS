extends Resource
class_name ComponentDB


# --------------------------------------------------------------------------------------------------
# "Export" Variables
# --------------------------------------------------------------------------------------------------
var _db : Dictionary = {}


# --------------------------------------------------------------------------------------------------
# Override Methods
# --------------------------------------------------------------------------------------------------
func _get(property : StringName):
	match property:
		&"db":
			return _db
	return null

func _set(property : StringName, value) -> bool:
	var success : bool = true
	
	match property:
		&"db":
			if typeof(value) == TYPE_DICTIONARY:
				set_database_dictionary(value, true)
			else : success = false
		_:
			success = false
	
	return success

func _get_property_list() -> Array:
	var arr : Array = [
		{
			name=&"db",
			type=TYPE_DICTIONARY,
			usage=PROPERTY_USAGE_STORAGE
		}
	]
	
	return arr


# --------------------------------------------------------------------------------------------------
# Public Methods
# --------------------------------------------------------------------------------------------------
func clear() -> void:
	_db.clear()

func size() -> int:
	return _db.size()

func is_empty() -> bool:
	return _db.is_empty()

func set_database_dictionary(db : Dictionary, fail_on_warnings : bool = false) -> int:
	var ndb : Dictionary = {}
	return OK


