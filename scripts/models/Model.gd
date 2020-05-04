class_name Model

enum ModelTypes {BOARD, LIST, CARD}

var model_type : int
var id : String

func _init(_model_type : int, _id : String):
	model_type = _model_type
	id = _id
