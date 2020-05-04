extends PanelContainer

var is_receiving_drag_data := false
var model : ListModel setget set_model, get_model
var is_dragged := false setget set_is_dragged
var is_any_data_dragged := false

onready var list_content := $MarginContainer

onready var card_scene := preload("res://scenes/Card.tscn")
onready var card_container := $MarginContainer/VerticalContent/CardContainerScroll/CardContainer
onready var card_container_scroll := $MarginContainer/VerticalContent/CardContainerScroll

onready var style_dragged := preload("res://assets/style_panel_list_dragged.tres")
onready var list_drag_preview := preload("res://scenes/ListPreview.tscn")

onready var title_label := $MarginContainer/VerticalContent/ListNameLabel
onready var add_card_button := $MarginContainer/VerticalContent/AddCardButton

func _ready():
	Events.connect("card_dragged", self, "_on_card_dragged")
	Events.connect("card_dropped", self, "_on_card_dropped")
	Events.connect("list_dragged", self, "_on_list_dragged")
	Events.connect("list_dropped", self, "_on_list_dropped")

func set_model(_model : ListModel):
	model = _model
	title_label.set_text(model.title)
	
	for card in model.cards:
		add_card(card)

func get_model():
	return model
	
func set_is_dragged(value := true):	
	if value:
		set("custom_styles/panel", style_dragged)
	else:
		set("custom_styles/panel", null)	

	list_content.set_visible(not value)
	is_dragged = value

func add_card(card : CardModel):
	var card_element = card_scene.instance()
	card_container.add_child(card_element)
	card_element.set_model(card)

func get_drag_data(_pos):		
	var list = list_drag_preview.instance()
	get_parent().add_child(list)
	list.set_data(self, get_model())
	get_parent().remove_child(list)
	set_drag_preview(list)

	set_is_dragged()

	Events.emit_signal("list_dragged", self, get_model())

	return list

func can_drop_data(mouse_pos, data):
	if data.model.model_type == Model.ModelTypes.CARD:
		is_receiving_drag_data = true
		
		var card_node = data.origin_node
		
		# If the Card comes from another List, reparent it
		if card_node.get_parent() != card_container:
			card_node.get_parent().remove_child(card_node)
			card_container.add_child(card_node)			
			
		# This List has more than 1 children, we need to calculate where to re-position
		# this Card relative to the closest Card in relation to the mouse position
		if card_container.get_child_count() > 1:
			var closest_card = _find_closest_card(mouse_pos, card_node)
			
			if closest_card:
				var curr_idx = card_node.get_index()		
				var closest_idx = closest_card[0].get_index()					
				var next_idx = max(0, closest_idx + (-1 if closest_card[1] else 0))
				card_container.move_child(card_node, next_idx)
								
		return true	
		
	is_receiving_drag_data = false
	return false

func drop_data(_pos, data):
	if data.model.model_type == Model.ModelTypes.CARD:
		Events.emit_signal("card_dropped", data)

func _find_closest_card(mouse_pos, compare_to):
	var closest_card
	var last_distance : float = -1
	var is_before := true
	
	# Add the scroll value to the mouse y-position.
	# The items in the list already account position with the amount scroll,
	# but the mouse position happens in screen space, that's why we need to add it.
	var scrolled_mouse_pos := Vector2(mouse_pos.x, mouse_pos.y + card_container_scroll.get_v_scroll())

	for child in card_container.get_children():
		var distance : float = child.get_position().distance_to(scrolled_mouse_pos)
				
		if last_distance == -1 or (distance < last_distance):
			last_distance = distance
			closest_card = child
			
	if closest_card:
		var y = closest_card.get_position().y
		var height = closest_card.get_size().y		
		is_before = scrolled_mouse_pos.y <= (y + height)
		return [closest_card, is_before]

func _on_card_dragged(_node, _model):
	is_any_data_dragged = true
	
func _on_card_dropped(drop_data):
	is_any_data_dragged = false

func _on_list_dragged(_node, _model):
	is_any_data_dragged = true
	set("mouse_filter", MOUSE_FILTER_PASS)
	
func _on_list_dropped(drop_data):
	is_any_data_dragged = false
	set("mouse_filter", MOUSE_FILTER_STOP)
	
	if drop_data and drop_data.origin_node == self:
		set_is_dragged(false)
