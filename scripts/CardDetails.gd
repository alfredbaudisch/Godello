extends Control

var can_close := true

onready var title_label := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/TitleRow/TitleContainer/Title
onready var title_edit := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/TitleRow/TitleContainer/TitleEdit
onready var subtitle_label := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/TitleRow/TitleContainer/Subtitle

onready var description_edit := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/DescriptionRow/VBoxContainer/DescriptionEdit

const CHECKITEM_SCENE := preload("res://scenes/CheckItem.tscn")
const POPUP_SCENE = preload("res://scenes/SingleButtonPopup.tscn")

onready var checkitem_edit_container := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/ChecklistRow/ChecklistContent/InputContainer
onready var checkitem_edit := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/ChecklistRow/ChecklistContent/InputContainer/CheckItemEdit
onready var checklist_row := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/ChecklistRow
onready var checklist_content := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/ChecklistRow/ChecklistContent
onready var checklist_items_container := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/ChecklistRow/ChecklistContent/Content

onready var close_button := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/TitleRow/CloseButton

var card : CardModel setget set_card
var list : ListModel setget set_list

signal close_details_requested

func _ready():
	DataRepository.connect("card_updated", self, "_on_card_updated")

func open(_model : CardModel):
	set_card(_model)	
	title_edit.set_visible(false)
	title_label.set_visible(true)	

func set_card(_model : CardModel):
	card = _model
	title_edit.set_text(card.title)
	title_label.set_text(card.title)
	description_edit.set_text(card.description)
	_sync_tasks()
	
	set_list(DataRepository.get_list(card.list_id))
	
func set_list(_model : ListModel):
	list = _model
	subtitle_label.set_bbcode("in list [u]" + list.title + "[/u]")

func _on_CloseButton_pressed():
	emit_signal("close_details_requested")

func _sync_tasks():
	_reset_checkitem_edit_container()
	
	for child in checklist_items_container.get_children():
		checklist_items_container.remove_child(child)
		child.queue_free()
		
	if card.tasks.size() > 0:
		checklist_row.set_visible(true)
		
		for task in card.tasks:
			var checkitem = CHECKITEM_SCENE.instance()
			checklist_items_container.add_child(checkitem)
			checkitem.set_model(task)			
			checkitem.connect("edit_check_item_requested", self, "_on_edit_check_item_requested")
			
	else:
		checklist_row.set_visible(false)

func _on_Title_gui_input(event):
	if event is InputEventMouseButton and event.get_button_index() == BUTTON_LEFT and not event.is_pressed():
		can_close = false
		title_edit.set_text(card.title)
		title_edit.set_visible(true)
		title_label.set_visible(false)
		title_edit.grab_focus()

func _on_SaveDescriptionButton_pressed():
	card.set_description(description_edit.get_text())
	
func _input(event):
	if Input.is_action_just_released("ui_cancel") and can_close:
		emit_signal("close_details_requested")

func _on_TitleEdit_gui_input(event):
	if event is InputEventKey and not event.is_pressed():
		match event.get_scancode():
			KEY_ENTER:
				var title = title_edit.get_text().replace("\n", "")
				if title == "":
					var popup = POPUP_SCENE.instance()
					popup.get_node("Label").set_text("Title is required.")
					add_child(popup)
					popup.popup_centered()
					
				else:
					card.set_title(title)
					title_edit.set_visible(false)
					title_label.set_visible(true)
					can_close = true
			
			KEY_ESCAPE:
				title_edit.set_visible(false)
				title_label.set_visible(true)
				can_close = true

func _on_SaveCheckItemButton_pressed():
	assert(checkitem_edit.get_text() != "")
	
	var result = DataRepository.create_task(card, checkitem_edit.get_text())
	checkitem_edit.set_text("")
	card = result["card"]
	_sync_tasks()

func _on_edit_check_item_requested(_node):	
	if checkitem_edit_container.get_parent() == checklist_content:
		checklist_content.remove_child(checkitem_edit_container)
	
	checklist_items_container.add_child_below_node(_node, checkitem_edit_container)
	checklist_items_container.move_child(_node, checkitem_edit_container.get_index() - 1)
	checkitem_edit.set_text(_node.model.title)

func _on_card_updated(_card):
	if card and _card.id == card.id:
		set_card(_card)

func _reset_checkitem_edit_container():
	checkitem_edit.set_text("")
	checkitem_edit_container.get_parent().remove_child(checkitem_edit_container)
	checklist_content.add_child(checkitem_edit_container)
