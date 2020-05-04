extends PanelContainer

onready var card_scene := preload("res://scenes/Card.tscn")
onready var card_container := $MarginContainer/VerticalContent/CardContainerScroll/CardContainer

onready var list_drag_preview := preload("res://scenes/ListPreview.tscn")

onready var title_label := $MarginContainer/VerticalContent/ListNameLabel
onready var add_card_button := $MarginContainer/VerticalContent/AddCardButton

var is_receiving_data := false
var model : ListModel setget set_model, get_model

func set_model(_model : ListModel):
	model = _model
	title_label.set_text(model.title)
	
	for card in model.cards:
		add_card(card)

func get_model():
	return model
	
func add_card(card : CardModel):
	var card_element = card_scene.instance()
	card_container.add_child(card_element)
	card_element.set_model(card)

func get_drag_data(_pos):
	print(_pos)
	var list = list_drag_preview.instance()
	get_parent().add_child(list)
	list.set_data(get_model())
	get_parent().remove_child(list)
	set_drag_preview(list)
	return list

func can_drop_data(_pos, data):
	if data.model.model_type == Model.ModelTypes.CARD:
		is_receiving_data = true
		print("IT IS A CARD, IT CAN ALSO CAN BE DROPPED")
		return true	
		
	is_receiving_data = false
	return false

func drop_data(_pos, data):
	if data.model.model_type == Model.ModelTypes.CARD:
		print("DROPPED CARD", data.model)
