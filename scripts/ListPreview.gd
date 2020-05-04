class_name ListPreview
extends PanelContainer

var title_label
var model : ListModel
var origin_node

onready var cards_container := $Panel/MarginContainer/VerticalContent/ScrollContainer/CardsContainer
onready var card_template := $Panel/MarginContainer/VerticalContent/ScrollContainer/CardsContainer/Card

func _ready():
	title_label = get_node("Panel/MarginContainer/VerticalContent/ListNameLabel")

func set_data(_node, _data : ListModel):
	origin_node = _node
	model = _data
	set_title(_data.title)	
	
	if _data.cards.size() == 0:
		card_template.set_visible(false)
		
func set_title(_title):
	title_label.set_text(_title)
