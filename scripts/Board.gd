extends Control

var is_receiving_drag_data = true

var list_id_to_container : Dictionary = {}

onready var list_scene := preload("res://scenes/List.tscn")
onready var list_container := $MarginContainer/ListContainerScroll/ListContainer
onready var list_container_scroll := $MarginContainer/ListContainerScroll

onready var card_details_container := $CardDetailsContainer
onready var card_details := $CardDetailsContainer/CardDetails

var is_card_details_open = false

func _ready():	
	Events.connect("card_clicked", self, "_on_card_clicked")
	card_details_container.set_visible(false)
	card_details.connect("close_details_requested", self, "_on_CardDetails_close_requested")
	
	for n in range(1, 3): # todo: iterate through existing lists
		var list_element = list_scene.instance()
		var list_id = str(n)
		
		var cards := []		
		for c in range(1, 5):
			var id = str(n) + " - " + str(c)# str(OS.get_ticks_usec())
			var card = CardModel.new(id, list_id, ("Card Title " + id))
			card.tasks = [
				TaskModel.new(str(n * c), id, "TASK " + id + ", 1"),
				TaskModel.new(str(n * c + 1), id, "TASK " + id + ", 2", true),
				TaskModel.new(str(n * c + 2), id, "TASK " + id + ", 3"),
			]
			cards.append(card)
		
		var list = ListModel.new(list_id, "TODO List " + list_id, cards)
		list_container.add_child(list_element)
		DataRepository.add_list(list, list_element)
		
		list_element.set_model(list)
		
func can_drop_data(mouse_pos, data):
	if data.drag_data["model"].model_type == Model.ModelTypes.LIST:
		is_receiving_drag_data = true

		var list_node = data.drag_data["node"]

		if list_node.get_parent() != list_container:
			list_node.get_parent().remove_child(list_node)
			list_container.add_child(list_node)			
			
		if list_container.get_child_count() > 1:
			var closest_list = DragUtils.find_closest_horizontal_child(mouse_pos, list_node, list_container, list_container_scroll)
			
			if closest_list[0]:
				var curr_idx = list_node.get_index()		
				var closest_idx = closest_list[0].get_index()					
				var next_idx = max(0, closest_idx + (-1 if closest_list[1] else 0))
				list_container.move_child(list_node, next_idx)
								
		return true	
		
	is_receiving_drag_data = false
	return false

func drop_data(_pos, data):
	if data.drag_data["model"].model_type == Model.ModelTypes.LIST:
		Events.emit_signal("list_dropped", data.drag_data)

func _on_card_clicked(model):
	card_details.open(model)
	card_details_container.set_visible(true)
	is_card_details_open = true
	
func _on_CardDetails_close_requested():
	card_details_container.set_visible(false)
	is_card_details_open = false
