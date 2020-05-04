extends MarginContainer

var model : CardModel setget set_model, get_model
var is_dragged := false setget set_is_dragged
var is_any_card_dragged := false

onready var style_default := preload("res://assets/style_panel_card.tres")
onready var style_dragged := preload("res://assets/style_panel_card_dragged.tres")

onready var content_container := $CardContent
onready var content_padding_container := $CardContent/InnerPadding
onready var title_label := $CardContent/InnerPadding/HBoxContainer/Title
onready var edit_icon := $CardContent/InnerPadding/HBoxContainer/EditIcon
onready var split := $CardContent/InnerPadding/HBoxContainer/Split

onready var card_drag_preview := preload("res://scenes/CardPreview.tscn")

func _ready():
	Events.connect("card_dragged", self, "_on_card_dragged")
	Events.connect("card_dropped", self, "_on_card_dropped")
	
	split.set_visible(true)
	edit_icon.set_visible(false)

func set_model(_model : CardModel):
	model = _model
	title_label.set_text(model.title)

func get_model():
	return model

func set_is_dragged(value := true):	
	if value:
		content_container.set("custom_styles/panel", style_dragged)
		title_label.set_visible_characters(0)
	else:
		content_container.set("custom_styles/panel", style_default)
		title_label.set_visible_characters(-1)		
		
	is_dragged = value

func get_drag_data(_pos):	
	var card = card_drag_preview.instance()
	get_parent().add_child(card)
	card.set_data(self, get_model())
	get_parent().remove_child(card)
	set_drag_preview(card)
	
	set_is_dragged()
	set_edit_icon_visibility(false)
	
	Events.emit_signal("card_dragged", self, get_model())
	
	return card
	
func set_edit_icon_visibility(is_visible : bool):
	edit_icon.set_visible(is_visible)
	split.set_visible(not is_visible)

func _on_Card_mouse_entered():
	if not is_dragged and not is_any_card_dragged:
		set_edit_icon_visibility(true)

func _on_Card_mouse_exited():
	if not is_dragged and not is_any_card_dragged:
		set_edit_icon_visibility(false)

func _on_card_dragged(_node, _model):
	is_any_card_dragged = true
	set("mouse_filter", MOUSE_FILTER_PASS)
	
func _on_card_dropped(drop_data):
	is_any_card_dragged = false
	set("mouse_filter", MOUSE_FILTER_STOP)
	
	if drop_data and drop_data.origin_node == self:
		set_is_dragged(false)
