class_name Model extends Object

enum ModelTypes {BOARD, LIST, CARD, TASK, USER}

var model_type : int
var id : int

func _init(_model_type : int, _id : int):
	model_type = _model_type
	id = _id
