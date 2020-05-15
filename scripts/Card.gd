extends MarginContainer

var model : CardModel setget set_model, get_model
var is_dragged := false setget set_is_dragged
var is_dragged_to_list setget set_dragged_to_list
var is_any_data_dragged := false

const STYLE_DEFAULT := preload("res://assets/style_panel_card.tres")
const STYLE_DRAGGED := preload("res://assets/style_panel_card_dragged.tres")

onready var content_container := $CardContent
onready var content_padding_container := $CardContent/InnerPadding
onready var title_label := $CardContent/InnerPadding/HBoxContainer/Title
onready var edit_icon := $CardContent/InnerPadding/HBoxContainer/EditIcon
onready var split := $CardContent/InnerPadding/HBoxContainer/Split

const CARD_DRAG_PREVIEW := preload("res://scenes/CardMousePreview.tscn")

func _ready():
	Events.connect("card_dragged", self, "_on_card_dragged")
	Events.connect("card_dropped", self, "_on_card_dropped")
	Events.connect("list_dragged", self, "_on_list_dragged")
	Events.connect("list_dropped", self, "_on_list_dropped")
	DataRepository.connect("card_updated", self, "_on_card_updated")
	
	split.set_visible(true)
	edit_icon.set_visible(false)

func set_model(_model : CardModel):
	model = _model
	if model.is_archived:
		queue_free()
	else:
		title_label.set_text(model.title)
		DataRepository.set_card_node(model, self)

func get_model():
	return model

func _unhandled_input(event):
	# Since Godot doesn't handle drops outside draggable boundaries,
	# we have to handle this by ourselves
	if event is InputEventMouseButton and is_dragged:		
		Events.emit_signal("card_dropped", DragUtils.get_drag_data(self, model), is_dragged_to_list)
		
func set_is_dragged(value := true):	
	if value:
		content_container.set("custom_styles/panel", STYLE_DRAGGED)
		title_label.set_visible_characters(0)
	else:
		content_container.set("custom_styles/panel", STYLE_DEFAULT)
		title_label.set_visible_characters(-1)		
		is_dragged_to_list = null
		
	is_dragged = value
	
func set_dragged_to_list(list):
	is_dragged_to_list = list

func get_drag_data(_pos):	
	var card = CARD_DRAG_PREVIEW.instance()
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
	if not is_dragged and not is_any_data_dragged:
		set_edit_icon_visibility(true)

func _on_Card_mouse_exited():
	if not is_dragged and not is_any_data_dragged:
		set_edit_icon_visibility(false)

func _on_card_dragged(_node, _model):
	is_any_data_dragged = true
	_ignore_mouse()
	
func _on_card_dropped(drop_data, _new_owner):
	is_any_data_dragged = false
	_default_mouse()
	
	if drop_data and drop_data["node"] == self:
		set_is_dragged(false)

func _on_list_dragged(_node, _model):
	is_any_data_dragged = true
	_ignore_mouse()

func _on_list_dropped(_drop_data):
	is_any_data_dragged = false
	_default_mouse()

func _ignore_mouse():
	set("mouse_filter", MOUSE_FILTER_PASS)

func _default_mouse():
	set("mouse_filter", MOUSE_FILTER_STOP)

func _on_Card_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.is_pressed():
		Events.emit_signal("card_clicked", model)

func _on_card_updated(_card):
	if model and _card.id == model.id:
		set_model(_card)
