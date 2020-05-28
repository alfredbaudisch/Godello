extends PanelContainer

signal menu_close_requested()

var board : BoardModel setget set_board

onready var back_button_holder := $MarginContainer/VerticalContent/HBoxContainer/BackButtonHolder
onready var back_button := $MarginContainer/VerticalContent/HBoxContainer/BackButton
onready var title_label := $MarginContainer/VerticalContent/HBoxContainer/TitleLabel

onready var menu_actions := $MarginContainer/VerticalContent/MenuActionsContainer

const CARD_SCENE := preload("res://scenes/Card.tscn")
onready var card_container_scroll := $MarginContainer/VerticalContent/CardContainerScroll
onready var card_container := $MarginContainer/VerticalContent/CardContainerScroll/CardContainer

func _ready():
	DataRepository.connect("card_updated", self, "_on_card_updated")
	
	_normalize_menu()
	
func _on_card_updated(_card):	
	_sync_archived_cards()
	
func set_board(_board : BoardModel):
	board = _board

func _sync_archived_cards():
	var amount_archived = board.archived_cards.size()
	var amount_placed = card_container.get_child_count()
	
	if not (amount_archived > 0 or (amount_archived != amount_placed)):
		return
	
	for child in card_container.get_children():
		child.queue_free()
	
	for card in board.archived_cards.values():
		_add_archived_card(card)
		
func _add_archived_card(card : CardModel):
	var card_element = CARD_SCENE.instance()
	card_container.add_child(card_element)
	card_element.set_is_in_archives(true)
	card_element.set_model(card)

func _on_CloseButton_pressed():
	emit_signal("menu_close_requested")

func _on_BackButton_pressed():
	_normalize_menu()
	
func _normalize_menu():
	title_label.set_text("Menu")
	back_button_holder.set_visible(true)
	back_button.set_visible(false)
	menu_actions.set_visible(true)
	card_container_scroll.set_visible(false)

func _on_ArchivedCardsButton_pressed():
	title_label.set_text("Archive")
	back_button_holder.set_visible(false)
	back_button.set_visible(true)
	menu_actions.set_visible(false)
	card_container_scroll.set_visible(true)
	_sync_archived_cards()	

func _on_EditBoardButton_pressed():
	SceneUtils.create_edit_title_dialog(SceneUtils.DialogMode.EDIT_BOARD, board)
