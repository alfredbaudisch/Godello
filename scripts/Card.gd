extends Panel

onready var panel = $"."
onready var edit_icon = $HBoxContainer/EditIcon
onready var title_label = $HBoxContainer/Title

var card_scene = preload("res://scenes/CardPreview.tscn")

func _ready():
	edit_icon.set_visible(false)

func _on_Card_mouse_entered():
	edit_icon.set_visible(true)

func _on_Card_mouse_exited():
	edit_icon.set_visible(false)

func get_drag_data(_pos):
	var card = card_scene.instance()
	get_parent().add_child(card)
	card.set_card_data(CardModel.new("123", "This is the title"))
	get_parent().remove_child(card)
	set_drag_preview(card)
	return card

func can_drop_data(_pos, data):
	if data.card_data:
		print("IT IS A CARD, CAN BE DROPPED")
		return true
	
	

func drop_data(_pos, data):
	pass
