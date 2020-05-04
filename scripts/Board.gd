extends Control

var lists : Array = []
var list_id_to_container : Dictionary = {}

onready var list_scene := preload("res://scenes/List.tscn")
onready var list_container := $MarginContainer/ScrollContainer/ListContainer

# Called when the node enters the scene tree for the first time.
func _ready():	
	for n in range(1, 3): # todo: iterate through existing lists
		var list_element = list_scene.instance()
		var list_id = str(n)
		
		var cards := []		
		for c in range(1, 10):
			var id = str(OS.get_ticks_usec())
			var card = CardModel.new(id, list_id, ("Card Title " + id).repeat(c))
			cards.append(card)
		
		var list = ListModel.new(list_id, "List " + list_id, cards)
		list_container.add_child(list_element)
		list_element.set_model(list)
