extends CheckBox

var model : TaskModel setget set_model

func set_model(_model):
	model = _model
	set_text(model.title)	
	set_pressed(model.is_done)
