extends ScrollContainer

onready var list_placeholder = preload("res://scenes/ListPlaceholder.tscn")
onready var list_container = $ListContainer

var is_receiving_data := false

var list_placeholders : Dictionary = {}

func can_drop_data(_pos, data):
	if data.model.model_type == Model.ModelTypes.LIST:
		get_placeholder_for_list(data.model.id)
		is_receiving_data = true
		return true	
		
	is_receiving_data = false
	return false

func drop_data(_pos, data):
	if data.model.model_type == Model.ModelTypes.LIST:
		is_receiving_data = false

func get_placeholder_for_list(list_id : String):
	var placeholder = list_placeholders.get(list_id)
	
	if not placeholder:
		placeholder = list_placeholder.instance()
		list_container.add_child(placeholder)
		list_placeholders[list_id] = placeholder
	
	return placeholder
