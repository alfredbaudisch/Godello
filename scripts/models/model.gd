class_name Model extends Resource


enum ModelTypes {BOARD, LIST, CARD, TASK, USER}

export(ModelTypes) var model_type
export(String) var id


# Needs default values to be loaded as custom resource
func _init(_model_type : int = ModelTypes.BOARD, _id : String = ""):
	model_type = _model_type
	id = _id
