extends Control

var is_receiving_drag_data = true

var lists : Array = []
var list_id_to_container : Dictionary = {}

onready var list_scene := preload("res://scenes/List.tscn")
onready var child_container := $MarginContainer/ListContainerScroll/ListContainer
onready var child_container_scroll := $MarginContainer/ListContainerScroll

func _ready():	
	for n in range(1, 20): # todo: iterate through existing lists
		var list_element = list_scene.instance()
		var list_id = str(n)
		
		var cards := []		
		for c in range(1, 10):
			var id = str(OS.get_ticks_usec())
			var card = CardModel.new(id, list_id, ("Card Title " + id).repeat(c))
			cards.append(card)
		
		var list = ListModel.new(list_id, "List " + list_id, cards)
		child_container.add_child(list_element)
		list_element.set_model(list)

func can_drop_data(mouse_pos, data):
	if data.model.model_type == Model.ModelTypes.LIST:
		is_receiving_drag_data = true

		var list_node = data.origin_node
		
		# If the Card comes from another List, reparent it
		if list_node.get_parent() != child_container:
			list_node.get_parent().remove_child(list_node)
			child_container.add_child(list_node)			
			
		# This List has more than 1 children, we need to calculate where to re-position
		# this list relative to the closest list in relation to the mouse position
		if child_container.get_child_count() > 1:
			var closest_list = _find_closest_child(mouse_pos, list_node)
			
			if closest_list:
				var curr_idx = list_node.get_index()		
				var closest_idx = closest_list[0].get_index()					
				var next_idx = max(0, closest_idx + (-1 if closest_list[1] else 0))
				child_container.move_child(list_node, next_idx)
								
		return true	
		
	is_receiving_drag_data = false
	return false

func drop_data(_pos, data):
	if data.model.model_type == Model.ModelTypes.LIST:
		Events.emit_signal("list_dropped", data)

func _find_closest_child(mouse_pos, compare_to):
	var closest_child
	var last_distance : float = -1
	var is_before := true
	
	var scrolled_mouse_pos := Vector2(mouse_pos.x + child_container_scroll.get_h_scroll(), mouse_pos.y)

	for child in child_container.get_children():
		var distance : float = child.get_position().distance_to(scrolled_mouse_pos)
		
		if last_distance == -1 or (distance < last_distance):
			last_distance = distance
			closest_child = child		
			
	if closest_child and closest_child != compare_to:
		var x = closest_child.get_position().x
		var width = closest_child.get_size().x		
		is_before = scrolled_mouse_pos.x <= (x + width * 0.5)
		return [closest_child, is_before]
		
