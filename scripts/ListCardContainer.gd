extends ScrollContainer

onready var style_receive_valid_data = preload("res://assets/style_list_receive_drag.tres")
onready var style_empty = preload("res://assets/style_empty.tres")

var is_receiving_data := false

func can_drop_data(_pos, data):
	if data.model.model_type == Model.ModelTypes.CARD:
		is_receiving_data = true
		set("custom_styles/bg", style_receive_valid_data)
		print("IT IS A CARD, IT CAN ALSO CAN BE DROPPED")
		return true	
		
	is_receiving_data = false
	set("custom_styles/bg", style_empty)
	return false

func drop_data(_pos, data):
	if data.model.model_type == Model.ModelTypes.CARD:
		_set_default_style()
		print("DROPPED CARD", data.model)

func _on_ListCardContainer_mouse_exited():
	_set_default_style()

func _set_default_style():
	if is_receiving_data:
		set("custom_styles/bg", style_empty)
		is_receiving_data = false	
