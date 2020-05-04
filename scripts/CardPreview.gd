class_name CardPreview
extends MarginContainer

var title_label
var model : CardModel
var origin_node

func _ready():
	title_label = get_node("Panel/HBoxContainer/Title")

func set_data(_node, _data : CardModel):
	origin_node = _node
	model = _data
	set_title(_data.title)
		
func set_title(_title):
	title_label.set_text(_title)
