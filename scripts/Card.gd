extends MarginContainer

var model : CardModel setget set_model, get_model
var is_dragged := false setget set_is_dragged

onready var style_default := preload("res://assets/style_panel_card.tres")
onready var style_dragged := preload("res://assets/style_panel_card_dragged.tres")

onready var content_container := $CardContent
onready var content_padding_container := $CardContent/InnerPadding
onready var title_label := $CardContent/InnerPadding/HBoxContainer/Title

func set_model(_model : CardModel):
	model = _model
	title_label.set_text(model.title)

func get_model():
	return model

func set_is_dragged(value := true):
	if value:
		content_container.set("custom_styles/panel", style_dragged)		
		title_label.set_visible_characters(0)		
		set("mouse_filter", MOUSE_FILTER_PASS)
		content_container.set("mouse_filter", MOUSE_FILTER_PASS)
		content_padding_container.set("mouse_filter", MOUSE_FILTER_PASS)		
	else:
		content_container.set("custom_styles/panel", style_default)		
		title_label.set_visible_characters(-1)		
		set("mouse_filter", MOUSE_FILTER_STOP)
		content_container.set("mouse_filter", MOUSE_FILTER_STOP)
		content_padding_container.set("mouse_filter", MOUSE_FILTER_STOP)
		
	is_dragged = value
