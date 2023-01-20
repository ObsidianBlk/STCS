# (D)ictionary (S)chema (V)erifier
@tool
extends Node

# ---
# NOTE: This is crude, ugly, and bare bones. I feel it does the job I need it to
#  but would need heavy work to make it more "universal" and error-proof.
#  You have been warned!
# ---


static func _VerifyIntValue(val : int, def : Dictionary) -> int:
	if &"min" in def:
		if def[&"min"] > val:
			return ERR_PARAMETER_RANGE_ERROR
	if &"max" in def:
		if def[&"max"] < val:
			return ERR_PARAMETER_RANGE_ERROR
	return OK

static func _VerifyStringValue(s : String, def : Dictionary) -> int:
	if s.strip_edges() == "":
		return ERR_PARAMETER_RANGE_ERROR
	return OK

static func _VerifyStringNameValue(s : StringName, def : Dictionary) -> int:
	if s.strip_edges() == &"":
		return ERR_PARAMETER_RANGE_ERROR
	return OK

static func _VerifyVec2IValue(val : Vector2i, def : Dictionary) -> int:
	if &"minmax" in def and def[&"minmax"] == true:
		if val.x > val.y:
			return ERR_PARAMETER_RANGE_ERROR
	return OK

static func _VerifyArrayValue(val : Array, def : Dictionary) -> int:
	if &"item" in def:
		var idef : Dictionary = def[&"item"]
		for v in val:
			if typeof(v) != idef[&"type"]:
				return ERR_INVALID_DATA
			var res : int = OK
			match idef[&"type"]:
				TYPE_INT:
					res = _VerifyIntValue(v, idef)
				TYPE_STRING:
					res = _VerifyStringValue(v, idef)
				TYPE_STRING_NAME:
					res = _VerifyStringNameValue(v, idef)
				TYPE_VECTOR2I:
					res = _VerifyVec2IValue(v, idef)
				TYPE_ARRAY:
					res = _VerifyArrayValue(v, idef)
				TYPE_DICTIONARY:
					res = verify(v, idef)
			if res != OK:
				return res
	return OK

static func verify_schema(s : Dictionary) -> int:
	# TODO: You know... actually write this method!
	# Not strictly needed for this current project, but this could be useful
	# in other projects, so, being able to verify schema dictionaries could be
	# rather useful.
	return OK

static func verify(d : Dictionary, schema : Dictionary) -> int:
	for key in schema.keys():
		if key in d:
			if typeof(d[key]) != schema[key][&"type"]:
				printerr("Data structure property \"%s\" value invalid type."%[key])
				return ERR_INVALID_DATA
		elif schema[key][&"req"] == true:
			printerr("Data structure missing required property \"%s\"."%[key])
			return ERR_INVALID_DECLARATION
			
			match schema[key][&"type"]:
				TYPE_INT:
					var res : int = _VerifyIntValue(d[key], schema[key])
					if res != OK:
						printerr("Data structure property \"%s\" value out of range."%[key])
						return res
				TYPE_STRING:
					var res : int = _VerifyStringValue(d[key], schema[key])
					if res != OK:
						printerr("Data structure property \"%s\" contains only white space."%[key])
						return res
				TYPE_STRING_NAME:
					var res : int = _VerifyStringNameValue(d[key], schema[key])
					if res != OK:
						printerr("Data structure property \"%s\" contains only white space."%[key])
						return res
				TYPE_VECTOR2I:
					var res : int = _VerifyVec2IValue(d[key], schema[key])
					if res != OK:
						printerr("Data structure property \"%s\" value out of range."%[key])
						return res
				TYPE_ARRAY:
					var res : int = _VerifyArrayValue(d[key], schema[key])
					if res != OK:
						printerr("Data structure array property \"%s\" contains invalid data or subtype."%[key])
						return res
				TYPE_DICTIONARY:
					if &"def" in schema[key]:
						var res : int = verify(d[key], schema[key][&"def"])
						if res != OK:
							printerr("Data structure dictionary property \"%s\" contains invalid data."%[key])
							return res
	return OK


