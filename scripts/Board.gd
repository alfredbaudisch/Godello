extends Control

var model : BoardModel setget set_model

var is_receiving_drag_data = true

var list_id_to_container : Dictionary = {}

const LIST_SCENE := preload("res://scenes/List.tscn")
const MENU_SCENE := preload("res://scenes/BoardMenu.tscn")
const CARD_DETAILS_SCENE := preload("res://scenes/CardDetails.tscn")

onready var list_container := $MarginContainer/VBoxContainer/ListContainerScroll/ListContainer
onready var list_container_scroll := $MarginContainer/VBoxContainer/ListContainerScroll
onready var add_list_button := $MarginContainer/VBoxContainer/ListContainerScroll/ListContainer/AddListButton
onready var full_screen_overlay := $FullScreenOverlay

var card_details

onready var title_label := $MarginContainer/VBoxContainer/BoardInfoContainer/TitleLabel

func set_model(_model):
	model = _model
	set_name("Board_" + model.id)	
	title_label.set_text(model.title)	

func _ready():	
	Events.connect("card_clicked", self, "_on_card_clicked")
	Events.connect("add_card_clicked", self, "_on_add_card_clicked")
	DataRepository.connect("list_created", self, "_on_list_created")
	DataRepository.connect("board_updated", self, "_on_board_updated")
	DataRepository.connect("board_deleted", self, "_on_board_deleted")
	
	full_screen_overlay.set_visible(false)
	
	var board = BoardModel.new("1", false, "A Trello Board")
	DataRepository.add_board(board)
	set_model(board)
	
	for n in range(1, 3): # todo: iterate through existing lists
		var list_element = LIST_SCENE.instance()
		var list_id = str(n)
		
		var cards := []		
		for c in range(1, 5):
			var id = str(n) + " - " + str(c)# str(OS.get_ticks_usec())
			var card = CardModel.new(id, list_id, ("Card Title " + id))
			if c != 1:
				card.tasks = [
					TaskModel.new(str(n * c), id, "TASK " + id + ", 1"),
					TaskModel.new(str(n * c + 1), id, "TASK " + id + ", 2", true),
					TaskModel.new(str(n * c + 2), id, "TASK " + id + ", 3"),
				]
			cards.append(card)
		
		var list = ListModel.new(list_id, model.id, "TODO List " + list_id, cards)
		list_container.add_child(list_element)
		DataRepository.add_list(list)
		
		list_element.set_model(list)
		
	_make_button_last_item()
		
func _make_button_last_item():
	var amount = list_container.get_child_count()  
	if amount > 1:
		list_container.move_child(add_list_button, amount - 1)
		
func can_drop_data(mouse_pos, data):
	if data.drag_data["model"].model_type == Model.ModelTypes.LIST:
		is_receiving_drag_data = true

		var list_node = data.drag_data["node"]

		if list_node.get_parent() != list_container:
			list_node.get_parent().remove_child(list_node)
			list_container.add_child(list_node)	     
			
		if (list_container.get_child_count() - 1) > 1:
			var closest_list = DragUtils.find_closest_horizontal_child(
				mouse_pos, list_node, list_container, list_container_scroll, "AddListButton"
			)
			
			if closest_list[0]:
				var curr_idx = list_node.get_index()		
				var closest_idx = closest_list[0].get_index()
				var next_idx = max(0, closest_idx + (-1 if closest_list[1] else 0))
				list_container.move_child(list_node, next_idx)
				
		_make_button_last_item()
		return true	
		
	is_receiving_drag_data = false
	return false

func drop_data(_pos, data):
	if data.drag_data["model"].model_type == Model.ModelTypes.LIST:
		Events.emit_signal("list_dropped", data.drag_data)

func _on_card_clicked(model):
	card_details = CARD_DETAILS_SCENE.instance()
	full_screen_overlay.add_child(card_details)
	card_details.set_card(model)
	full_screen_overlay.set_visible(true)
	
	# Yield until the details modal is exited (when closed, it removes itself with queue_free).
	yield(card_details, "tree_exited")	
	full_screen_overlay.set_visible(false)

func _on_add_card_clicked(list):
	card_details = CARD_DETAILS_SCENE.instance()
	full_screen_overlay.add_child(card_details)
	
	var draft_card = DataRepository.get_draft_card(list)
	card_details.set_card(draft_card)
	full_screen_overlay.set_visible(true)
	
	yield(card_details, "tree_exited")	
	full_screen_overlay.set_visible(false)

func _add_list(list : ListModel):
	var list_element = LIST_SCENE.instance()	
	list_container.add_child(list_element)	
	list_element.set_model(list)
	_make_button_last_item()
	
func _on_list_created(list : ListModel):
	if list and list.board_id == model.id:
		_add_list(list)
		
func _on_board_updated(board):
	if model and board.id == model.id:
		set_model(board)
		
func _on_board_deleted(board):
	if model and board.id == model.id:		
		SceneUtils.go_to_boards()		

# Instantiate and animate the opening of the Main Menu.
# 
# The idea of this method is to illustrate how to do everything dynamically.
func _on_ShowMenuButton_pressed():
	var menu = MENU_SCENE.instance()
	add_child(menu)
	move_child(menu, get_child_count() - 2)	
	
	menu.set_board(model)
	
	var open_margin = menu.rect_size.x * -1
	
	# If we tween the position, as soon as the viewport is resized, the menu
	# will stay in place. By tweening the margin, the menu
	# moves with the viewport resizing.
	var tween = Tween.new()
	add_child(tween)	
	tween.interpolate_property(menu, 
		"margin_left", 0, open_margin, 0.2,
		Tween.TRANS_SINE, Tween.EASE_IN)
	tween.start()
	
	yield(tween, "tween_completed")
	tween.queue_free()	
	
	yield(menu, "menu_close_requested")
	
	tween = Tween.new()
	add_child(tween)	
	tween.interpolate_property(menu, 
		"margin_left", open_margin, 0, 0.2,
		Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()
	
	yield(tween, "tween_completed")
	tween.queue_free()	
	menu.queue_free()

func _on_AddListButton_pressed():
	SceneUtils.create_edit_title_dialog(SceneUtils.DialogMode.CREATE_LIST, model)
