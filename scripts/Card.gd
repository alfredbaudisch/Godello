extends MarginContainer

var model : CardModel setget set_model, get_model
var is_dragged := false setget set_is_dragged

onready var title_label := $CardContent/InnerPadding/HBoxContainer/Title

func set_model(_model : CardModel):
	model = _model
	title_label.set_text(model.title)

func get_model():
	return model

func set_is_dragged(value := true):
	is_dragged = value	
	set_visible(not value)
