# (D)ictionary (S)chema (V)erifier
# Author: Bryan Miller
# Version: 0.0.2
#
# The intent of this script is to allow users to validate the data contained in
# a dictionary against a specially formatted schema dictionary.
#
# 

@tool
extends Node

# ---
# NOTE: This is crude, ugly, and bare bones. I feel it does the job I need it to
#  but would need heavy work to make it more "universal" and error-proof.
#  You have been warned!
# ---

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
const ALLOWED_TYPES : PackedByteArray = [
	TYPE_BOOL,
	TYPE_ARRAY, TYPE_DICTIONARY,
	TYPE_INT, TYPE_FLOAT,
	TYPE_STRING, TYPE_STRING_NAME,
	TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_VECTOR3, TYPE_VECTOR3I, TYPE_VECTOR4, TYPE_VECTOR4I,
	TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_COLOR_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY,
	TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_STRING_ARRAY,
	TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY,
]

# ------------------------------------------------------------------------------
# Helper Class
# ------------------------------------------------------------------------------
class RefSchema:
	var _refs : Dictionary = {}
	var _parent : RefSchema = null
	
	func _init(parent : RefSchema) -> void:
		_parent = parent
	
	func has_ref_schema(name : StringName) -> bool:
		if name in _refs: return true
		if _parent != null:
			return _parent.has_ref_schema(name)
		return false
	
	func add_ref_schema(name : StringName, schema : Dictionary) -> int:
		if name in _refs:
			return ERR_ALREADY_IN_USE
		if _parent != null:
			if _parent.has_ref_schema(name):
				return ERR_ALREADY_IN_USE
		_refs[name] = schema
		return OK
	
	func get_ref_schema(name : StringName) -> Dictionary:
		if name in _refs:
			return _refs[name]
		if _parent != null:
			return _parent.get_ref_schema(name)
		return {}

# ------------------------------------------------------------------------------
# Static Private Methods
# ------------------------------------------------------------------------------

static func _VerifyIntValue(val : int, def : Dictionary, state : Dictionary) -> int:
	if &"one_of" in def and (typeof(def[&"one_of"]) == TYPE_PACKED_INT32_ARRAY or typeof(def[&"one_of"]) == TYPE_PACKED_INT64_ARRAY):
		if def[&"one_of"].find(val) < 0:
			printerr("VALIDATION ERROR [", state[&"path"], "]: Value does not match one of the expected values.")
			return ERR_DOES_NOT_EXIST
	else:
		if &"min" in def and def[&"min"] > val:
			printerr("VALIDATION ERROR [", state[&"path"], "]: Value less than minimum.")
			return ERR_PARAMETER_RANGE_ERROR
		if &"max" in def and def[&"max"] < val:
			printerr("VALIDATION ERROR [", state[&"path"], "]: Value greater than maximum.")
			return ERR_PARAMETER_RANGE_ERROR
	return OK

static func _VerifyFloatValue(val : float, def : Dictionary, state : Dictionary) -> int:
	if &"min" in def:
		if def[&"min"] > val:
			printerr("VALIDATION ERROR [", state[&"path"], "]: Value less than minimum.")
			return ERR_PARAMETER_RANGE_ERROR
	if &"max" in def:
		if def[&"max"] < val:
			printerr("VALIDATION ERROR [", state[&"path"], "]: Value greater than maximum.")
			return ERR_PARAMETER_RANGE_ERROR
	return OK

static func _VerifyStringValue(s : String, def : Dictionary, state : Dictionary) -> int:
	var allow_empty : bool = true
	if &"one_of" in def and typeof(def[&"one_of"]) == TYPE_PACKED_STRING_ARRAY:
		if def[&"one_of"].find(s) < 0:
			printerr("VALIDATION ERROR [", state[&"path"], "]: Value does not match one of the expected values.")
			return ERR_DOES_NOT_EXIST
	elif &"none_of" in def and typeof(def[&"none_of"]) == TYPE_PACKED_STRING_ARRAY:
		if def[&"none_of"].find(s) >= 0:
			printerr("VALIDATION ERROR [", state[&"path"], "]: Value matches an exclusion value.")
			return ERR_INVALID_DATA
	if &"allow_empty" in def and typeof(def[&"allow_empty"]) == TYPE_BOOL:
		allow_empty = def[&"allow_empty"]
	if allow_empty == false and s.strip_edges() == "":
		printerr("VALIDATION ERROR [", state[&"path"], "]: Value is empty string.")
		return ERR_PARAMETER_RANGE_ERROR
	return OK

static func _VerifyStringNameValue(s : StringName, def : Dictionary, state : Dictionary) -> int:
	var allow_empty : bool = true
	if &"one_of" in def and typeof(def[&"one_of"]) == TYPE_PACKED_STRING_ARRAY:
		if def[&"one_of"].find(s) < 0:
			printerr("VALIDATION ERROR [", state[&"path"], "]: Value does not match one of the expected values.")
			return ERR_DOES_NOT_EXIST
	elif &"none_of" in def and typeof(def[&"none_of"]) == TYPE_PACKED_STRING_ARRAY:
		if def[&"none_of"].find(s) >= 0:
			printerr("VALIDATION ERROR [", state[&"path"], "]: Value matches an exclusion value.")
			return ERR_INVALID_DATA
	if &"allow_empty" in def and typeof(def[&"allow_empty"]) == TYPE_BOOL:
		allow_empty = def[&"allow_empty"]
	if allow_empty == false and s.strip_edges() == &"":
		printerr("VALIDATION ERROR [", state[&"path"], "]: Value is empty string.")
		return ERR_PARAMETER_RANGE_ERROR
	return OK

static func _VerifyVec2IValue(val : Vector2i, def : Dictionary, state : Dictionary) -> int:
	if &"minmax" in def and def[&"minmax"] == true:
		if val.x > val.y:
			printerr("VALIDATION ERROR [", state[&"path"], "]: X(min) and Y(max) out of order.")
			return ERR_PARAMETER_RANGE_ERROR
	return OK

static func _VerifyArrayValue(val : Array, def : Dictionary, state : Dictionary) -> int:
	var base_path : String = state[&"path"]
	var refs : RefSchema = null if not &"refs" in state else state[&"refs"]
	
	var idef : Dictionary = {}
	if &"item_ref" in def:
		if refs != null:
			idef = refs.get_ref_schema(def[&"item_ref"])
		if idef.is_empty():
			printerr("VALIDATION WARNING [", base_path, "]: Referencing undefined sub-schema \"", def[&"item_ref"], "\". Validation may be effected.")
	elif &"item" in def:
		idef = def[&"item"]
	
	if not idef.is_empty():
		for i in range(val.size()):
			var v = val[i]
			var path : String = "%s[%d]"%[base_path, i]
			
			if not &"type" in idef:
				printerr("VALIDATION ERROR [", path, "]: Schema for entry missing required 'type' property.")
				return ERR_INVALID_DECLARATION
			if ALLOWED_TYPES.find(idef[&"type"]) < 0:
				printerr("VALIDATION ERROR [", path, "]: Schema 'type' property invalid value.")
				return ERR_INVALID_DECLARATION
			
			if typeof(v) != idef[&"type"]:
				printerr("VALIDATION ERROR [", path, "]: Unexpected entry type.")
				return ERR_INVALID_DATA
			var res : int = OK
			match idef[&"type"]:
				TYPE_INT:
					res = _VerifyIntValue(v, idef, {&"path":path})
				TYPE_STRING:
					res = _VerifyStringValue(v, idef, {&"path":path})
				TYPE_STRING_NAME:
					res = _VerifyStringNameValue(v, idef, {&"path":path})
				TYPE_VECTOR2I:
					res = _VerifyVec2IValue(v, idef, {&"path":path})
				TYPE_ARRAY:
					res = _VerifyArrayValue(v, idef, {&"path":path, &"refs":refs})
				TYPE_DICTIONARY:
					if &"def" in idef:
						res = _VerifyDictionaryValue(v, idef[&"def"], {&"path":path, &"refs":refs})
			if res != OK:
				return res
	return OK

static func _VerifyDictionaryValue(val : Dictionary, def : Dictionary, state : Dictionary) -> int:
	var base_path : String = "ROOT" if not &"path" in state else state[&"path"]
	var refs : RefSchema = null if not &"refs" in state else state[&"refs"]
	
	if &"!REFS" in def and typeof(def[&"!REFS"]) == TYPE_DICTIONARY:
		refs = RefSchema.new(refs)
		for key in def[&"!REFS"]:
			if typeof(def[&"!REFS"][key]) == TYPE_DICTIONARY:
				var res : int = refs.add_ref_schema(key, def[&"!REFS"][key])
				if res != OK:
					printerr("VALIDATION WARNING: Schema redefining sub-schema \"", key, "\". Validation may be effected.")
	
	# Determines if only validation should fail if dictionary has keys other than the ones defined.
	# By default, this is true.
	var only_def : bool = true
	if &"!ONLY_DEF" in def and typeof(def[&"!ONLY_DEF"]) == TYPE_BOOL:
		only_def = def[&"!ONLY_DEF"]
	
	if only_def:
		for vkey in val.keys():
			if not vkey in def:
				printerr("VALIDATION ERROR [", base_path, "]: Object key \"", vkey, "\" not defined in Schema.")
				return ERR_CANT_RESOLVE
	
	for key in def.keys():
		if key.begins_with("!"):
			continue # These are state directives. We don't process these at this point
		
		var path : String = key
		if base_path != "ROOT":
			path = "%s.%s"%[base_path, key]
		
		if not key in val:
			if def[key][&"req"] == true:
				printerr("VALIDATION ERROR [", base_path, "]: Data structure missing required property \"", key, "\".")
				return ERR_INVALID_DECLARATION
			continue
		
		var schema : Dictionary = {}
		if &"ref" in def[key]:
			if refs != null:
				schema = refs.get_ref_schema(def[key][&"ref"])
			if schema.is_empty():
				printerr("VALIDATION ERROR [", base_path, "]: Referencing undefined sub-schema \"", def[key][&"ref"], "\". Validation may be effected.")
				return ERR_DOES_NOT_EXIST
		else:
			schema = def[key]
		
		if not &"type" in schema:
			printerr("VALIDATION ERROR [", base_path, "]: Schema for entry missing required 'type' property.")
			return ERR_INVALID_DECLARATION
		if ALLOWED_TYPES.find(schema[&"type"]) < 0:
			printerr("VALIDATION ERROR [", base_path, "]: Schema 'type' property invalid value.")
			return ERR_INVALID_DECLARATION
		
		if typeof(val[key]) != schema[&"type"]:
			printerr("VALIDATION ERROR [", base_path, "]: Data structure property \"", key, "\" value invalid type.")
			return ERR_INVALID_DATA
		
		match schema[&"type"]:
			TYPE_INT:
				var res : int = _VerifyIntValue(val[key], schema, {&"path":path})
				if res != OK:
					return res
			TYPE_STRING:
				var res : int = _VerifyStringValue(val[key], schema, {&"path":path})
				if res != OK:
					return res
			TYPE_STRING_NAME:
				var res : int = _VerifyStringNameValue(val[key], schema, {&"path":path})
				if res != OK:
					return res
			TYPE_VECTOR2I:
				var res : int = _VerifyVec2IValue(val[key], schema, {&"path":path})
				if res != OK:
					return res
			TYPE_ARRAY:
				var res : int = _VerifyArrayValue(val[key], schema, {&"path":path, &"refs":refs})
				if res != OK:
					return res
			TYPE_DICTIONARY:
				if &"def" in schema:
					var res : int = _VerifyDictionaryValue(val[key], schema[&"def"], {&"path":path, &"refs":refs})
					if res != OK:
						return res
	return OK


# ------------------------------------------------------------------------------
# Static Public Methods
# ------------------------------------------------------------------------------

static func verify_schema(s : Dictionary) -> int:
	if s.is_empty():
		pass
	# TODO: You know... actually write this method!
	# Not strictly needed for this current project, but this could be useful
	# in other projects, so, being able to verify schema dictionaries could be
	# rather useful.
	return OK

static func verify(d : Dictionary, schema : Dictionary) -> int:
	return _VerifyDictionaryValue(d, schema, {})


