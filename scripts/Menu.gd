extends PanelContainer

signal menu_close_requested()

onready var back_button_holder := $MarginContainer/VerticalContent/HBoxContainer/BackButtonHolder
onready var back_button := $MarginContainer/VerticalContent/HBoxContainer/BackButton
onready var title_label := $MarginContainer/VerticalContent/HBoxContainer/TitleLabel

onready var menu_actions := $MarginContainer/VerticalContent/MenuActionsContainer

func _ready():
	_normalize_menu()

func _on_CloseButton_pressed():
	emit_signal("menu_close_requested")

func _on_BackButton_pressed():
	_normalize_menu()
	
func _normalize_menu():
	title_label.set_text("Menu")
	back_button_holder.set_visible(true)
	back_button.set_visible(false)
	menu_actions.set_visible(true)

func _on_ArchivedCardsButton_pressed():
	title_label.set_text("Archive")
	back_button_holder.set_visible(false)
	back_button.set_visible(true)
	menu_actions.set_visible(false)
