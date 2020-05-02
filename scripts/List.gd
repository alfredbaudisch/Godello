extends MarginContainer

onready var title_label = $VerticalContent/ListNameLabel

var list_preview_scene = preload("res://scenes/ListPreview.tscn")

func _ready():
	print("List Ready")

func get_drag_data(_pos):
	print(_pos)
	var list = list_preview_scene.instance()
	get_parent().add_child(list)
	list.set_data(ListModel.new("123", title_label.get_text()))
	get_parent().remove_child(list)
	set_drag_preview(list)
	return list
