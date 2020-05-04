class_name DragUtils extends Object

static func find_closest_horizontal_child(mouse_pos, compare_to, container, container_scroll) -> Array:
	var closest_child
	var last_distance : float = -1
	var is_before := true
	
	var scrolled_mouse_pos := Vector2(mouse_pos.x + container_scroll.get_h_scroll(), mouse_pos.y)

	for child in container.get_children():
		var distance : float = child.get_position().distance_to(scrolled_mouse_pos)
		
		if last_distance == -1 or (distance < last_distance):
			last_distance = distance
			closest_child = child		
			
	if closest_child and closest_child != compare_to:
		var x = closest_child.get_position().x
		var width = closest_child.get_size().x		
		is_before = scrolled_mouse_pos.x <= (x + width * 0.5)
		return [closest_child, is_before]

	return [false]
		
static func find_closest_vertical_child(mouse_pos, compare_to, container, container_scroll) -> Array:
	var closest_child
	var last_distance : float = -1
	var is_before := true
	
	var scrolled_mouse_pos := Vector2(mouse_pos.x, mouse_pos.y + container_scroll.get_v_scroll())

	for child in container.get_children():
		var distance : float = child.get_position().distance_to(scrolled_mouse_pos)
		
		if last_distance == -1 or (distance < last_distance):
			last_distance = distance
			closest_child = child		
			
	if closest_child and closest_child != compare_to:
		var y = closest_child.get_position().y
		var height = closest_child.get_size().y		
		is_before = scrolled_mouse_pos.y <= (y + height * 0.5)
		return [closest_child, is_before]

	return [false]
