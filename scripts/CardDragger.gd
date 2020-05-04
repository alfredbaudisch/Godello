extends MarginContainer

onready var panel = $"."
onready var edit_icon = $HBoxContainer/EditIcon
onready var title_label = $HBoxContainer/Title
onready var split = $HBoxContainer/Split

var card_scene = preload("res://scenes/CardPreview.tscn")

func _ready():
	split.set_visible(true)
	edit_icon.set_visible(false)

func _on_Card_mouse_entered():
	edit_icon.set_visible(true)
	split.set_visible(false)

func _on_Card_mouse_exited():
	edit_icon.set_visible(false)
	split.set_visible(true)

func get_drag_data(_pos):
	var owner_card_element = get_parent().get_parent()
	
	var card = card_scene.instance()
	get_parent().add_child(card)
	card.set_data(owner_card_element.get_model())
	get_parent().remove_child(card)
	set_drag_preview(card)
	owner_card_element.set_is_dragged()
	
	return card
