extends Node


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal database_added(db_name)
signal database_removed(db_name)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CDB_PATH : String = "res://data/cdb/"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _dbcollection : Dictionary = {}

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func add_database_resource(db : ComponentDB, auto_save_db : bool = true) -> int:
	if db.name.strip_edges() == "":
		return ERR_UNCONFIGURED
	var sha : StringName = db.name.sha256_text()
	if sha in _dbcollection:
		return ERR_ALREADY_IN_USE
	_dbcollection[sha] = {
		&"db": db,
		&"file_path": "CDB_%s.res"%[sha]
	}
	database_added.emit(db.name)
	return OK

