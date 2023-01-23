@tool
extends Node


const LOW_BYTE : int = 0xFF

static func _rng() -> int:
	randomize()
	return randi() & LOW_BYTE

static func bin4() -> PackedByteArray:
	return PackedByteArray([
		_rng(), _rng(), _rng(), _rng(),
		_rng(), _rng(),
		(_rng() & 0x0F) | 0x4F, _rng(),
		_rng(), _rng(),
		_rng(), _rng(), _rng(), _rng(), _rng(), _rng()
	])

static func v4() -> StringName:
	var bin : PackedByteArray = bin4()
	return StringName("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x"%[
		bin[0], bin[1], bin[2], bin[3],
		bin[4], bin[5],
		bin[6], bin[7],
		bin[8], bin[9],
		bin[10], bin[11], bin[12], bin[13], bin[14], bin[15]
	])
