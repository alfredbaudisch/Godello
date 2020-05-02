class_name CardPreview
extends MarginContainer

var title_label
var card_data : CardModel

func _ready():
	title_label = get_node("Panel/HBoxContainer/Title")

func set_data(_data : CardModel):
	card_data = _data
	set_title(_data.title)
		
func set_title(_title):
	title_label.set_text(_title)
