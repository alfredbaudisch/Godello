class_name CardPreview
extends MarginContainer

var title_label
var card_data : CardModel

func _ready():
	title_label = get_node("Panel/HBoxContainer/Title")

func set_card_data(_card_data : CardModel):
	card_data = _card_data
	set_title(_card_data.title)
		
func set_title(_title):
	title_label.set_text(_title)
