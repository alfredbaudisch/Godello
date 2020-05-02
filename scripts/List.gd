extends Panel

onready var title_label = $MarginContainer/VerticalContent/ListNameLabel

var list_preview_scene = preload("res://scenes/ListPreview.tscn")

func _ready():
	print("List Ready")

func get_drag_data(_pos):
	var list = list_preview_scene.instance()
	#get_parent().add_child(list)
	#list.set_card_data(ListModel.new("123", "List Title"))
	#get_parent().remove_child(list)
	set_drag_preview(list)
	return list

func can_drop_data(_pos, data):
	if data.list_data:
		print("IT IS A LIST, CAN BE DROPPED")
		return true
	elif data.card_data:
		print("IT IS A CARD, IT CAN ALSO CAN BE DROPPED")
		return true	
	
	return false

func drop_data(_pos, data):
	pass
