class_name Model extends Object

enum ModelTypes {BOARD, LIST, CARD}

var model_type

func _init(_model_type : int):
	model_type = _model_type
