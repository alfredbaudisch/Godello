class_name CardPreview
extends MarginContainer

var title_label
var model : CardModel

func _ready():
	title_label = get_node("Panel/HBoxContainer/Title")

func set_data(_data : CardModel):
	model = _data
	set_title(_data.title)
		
func set_title(_title):
	title_label.set_text(_title)
