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
	var card = card_scene.instance()
	get_parent().add_child(card)
	card.set_data(CardModel.new("123", title_label.get_text()))
	get_parent().remove_child(card)
	set_drag_preview(card)
	return card
