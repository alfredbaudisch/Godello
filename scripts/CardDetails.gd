extends Control


var can_close := true
var is_save_title_manually_requested := false
var popup

onready var title_label := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/TitleRow/TitleContainer/Title
onready var title_edit := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/TitleRow/TitleContainer/TitleEdit
onready var subtitle_label := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/TitleRow/TitleContainer/Subtitle

onready var description_edit := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/DescriptionRow/VBoxContainer/DescriptionEdit

const CHECKITEM_SCENE := preload("res://scenes/CheckItem.tscn")
const POPUP_SCENE = preload("res://scenes/SingleButtonPopup.tscn")

onready var checkitem_edit_container := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/ChecklistRow/ChecklistContent/EditContainer
onready var checkitem_edit := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/ChecklistRow/ChecklistContent/EditContainer/CheckItemEdit
onready var checkitem_create_container := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/ChecklistRow/ChecklistContent/CreateContainer
onready var checkitem_create := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/ChecklistRow/ChecklistContent/CreateContainer/CheckItemEdit
onready var checklist_row := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/ChecklistRow
onready var checklist_content := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/ChecklistRow/ChecklistContent
onready var checklist_items_container := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/DetailsCol/ChecklistRow/ChecklistContent/Content

onready var archived_label := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ArchivedNoticeLabel
onready var archive_button := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/ActionsCol/ArchiveCardButton

onready var contents_row := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow
onready var actions_col := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/ContentRow/ActionsCol
onready var close_button := $ScrollContainer/PanelContainer/MarginContainer/VBoxContainer/TitleRow/CloseButton

var card : CardModel setget set_card
var list : ListModel setget set_list
var task : TaskModel

func _ready():
	DataRepository.connect("card_updated", self, "_on_card_updated")
	DataRepository.connect("card_created", self, "_on_card_updated")
	title_edit.set_visible(false)
	title_label.set_visible(true)	

func set_card(_model : CardModel):
	card = _model
	title_edit.set_text(card.title)
	title_label.set_text(card.title)
	description_edit.set_text(card.description)
	_sync_tasks()
	
	set_list(DataRepository.get_list(card.list_id))
	
	contents_row.set_visible(not card.is_draft)
	title_edit.set_visible(card.is_draft)
	title_label.set_visible(not card.is_draft)
	
	archived_label.set_visible(card.is_archived)
	if card.is_archived:		
		archive_button.set_text("Unarchive")
	else:
		archive_button.set_text("Archive")
	
func set_list(_model : ListModel):
	list = _model
	subtitle_label.set_bbcode("in list [u]" + list.title + "[/u]")		

func _on_CloseButton_pressed():
	queue_free()

func _sync_tasks():
	_reset_checkitem_edit_container()
	
	for child in checklist_items_container.get_children():
		checklist_items_container.remove_child(child)
		child.queue_free()
		
	checklist_row.set_visible(true)
	
	if card.tasks.size() > 0:
		for task in card.tasks:
			var checkitem = CHECKITEM_SCENE.instance()
			checklist_items_container.add_child(checkitem)
			checkitem.set_model(task)			
			checkitem.connect("edit_check_item_requested", self, "_on_edit_check_item_requested")
			checkitem.connect("toggled", self, "_on_check_item_toggled", [task])
		
func _on_SaveDescriptionButton_pressed():
	card.set_description(description_edit.get_text())
	
func _input(event):
	if Input.is_action_just_released("ui_cancel"):
		if popup:
			popup.queue_free()		
		elif can_close:
			queue_free()

func _on_card_updated(_card):
	if card and _card.id == card.id:
		set_card(_card)

func _create_single_error_popup(message : String, focus_after_close : Control):
	popup = POPUP_SCENE.instance()
	popup.get_node("Label").set_text(message)
	add_child(popup)
	popup.popup_centered()
	
	yield(popup, "tree_exited")
	popup = null
	focus_after_close.grab_focus()
	
#
# Title
#

func _on_TitleEdit_gui_input(event):
	if event is InputEventKey and not event.is_pressed():
		match event.get_scancode():
			KEY_ENTER:
				is_save_title_manually_requested = true
				_save_card_title()
			
			# Cancel changes
			KEY_ESCAPE:
				title_edit.set_text(card.title)
				_close_edit_card_title()

func _close_edit_card_title():
	title_edit.set_visible(false)
	title_label.set_visible(true)
	can_close = true
	is_save_title_manually_requested = false
	
func _save_card_title():
	var title = title_edit.get_text().replace("\n", "").replace("\t", "").trim_suffix(" ").trim_prefix(" ")
	
	if title != "" and card.title == title:
		_close_edit_card_title()
		return
		
	if title == "" and (not card.is_draft or (card.is_draft and is_save_title_manually_requested)):
		_create_single_error_popup("Title is required.", title_edit)
		is_save_title_manually_requested = false
		return
	
	card.set_title(title)
	_close_edit_card_title()

func _on_TitleEdit_focus_exited():	
	if not is_save_title_manually_requested:
		_save_card_title()

func _on_Title_gui_input(event):
	if event is InputEventMouseButton and event.get_button_index() == BUTTON_LEFT and not event.is_pressed():
		can_close = false
		title_edit.set_text(card.title)
		title_edit.set_visible(true)
		title_label.set_visible(false)
		title_edit.grab_focus()

#
# Checkitem / Task
#

func _on_CheckItemEdit_gui_input(event, is_create):
	if event is InputEventKey and not event.is_pressed():
		match event.get_scancode():
			KEY_ENTER:
				_save_checkitem_task(is_create)

			KEY_ESCAPE:
				_cancel_checkitem_task_edit()
				
func _reset_checkitem_edit_container():
	checkitem_create_container.set_visible(true)
	checkitem_edit_container.set_visible(false)
	
	if checkitem_edit_container.get_parent() != checklist_content:
		checkitem_edit_container.get_parent().remove_child(checkitem_edit_container)
		checklist_content.add_child_below_node(checkitem_create_container, checkitem_edit_container)
	
func _on_SaveCheckItemButton_pressed(is_create):	
	_save_checkitem_task(is_create)
		
func _save_checkitem_task(is_create := true):
	var input_field = checkitem_create if is_create else checkitem_edit
	var title = input_field.get_text().replace("\n", "").trim_suffix(" ").trim_prefix(" ")
	
	if title == "":
		_create_single_error_popup("Task description is required.", input_field)
	elif is_create:
		DataRepository.create_task(card, title)
		input_field.set_text("")
	else:
		card.update_task(task, title, task.is_done)
	
func _on_DeleteCheckItemButton_pressed():
	card.delete_task(task)
	_cancel_checkitem_task_edit()
	
func _cancel_checkitem_task_edit():
	checkitem_create_container.set_visible(true)
	checkitem_edit_container.set_visible(false)
	checkitem_create.set_text("")
	
	# We need to lose the focus off of the container,
	# since there is no direct method, set focus to anything else
	close_button.grab_focus()

func _on_edit_check_item_requested(_node):	
	if checkitem_edit_container.get_parent() == checklist_content:
		checklist_content.remove_child(checkitem_edit_container)
	
	task = _node.model
	checkitem_edit.set_text(_node.model.title)
	checkitem_edit_container.set_visible(true)
	checkitem_create_container.set_visible(false)
	checklist_items_container.add_child_below_node(_node, checkitem_edit_container)
	checklist_items_container.move_child(_node, checkitem_edit_container.get_index() - 1)	

func _on_CancelCheckItemButton_pressed():
	_cancel_checkitem_task_edit()

func _on_check_item_toggled(is_toggled, task):
	card.update_task(task, task.title, not task.is_done)

func _on_CheckItemEdit_focus_entered():
	can_close = false

func _on_CheckItemEdit_focus_exited():
	can_close = true

#
# Actions
#

func _on_ArchiveCardButton_pressed():
	card.archive() if not card.is_archived else card.unarchive()

func _on_DeleteCardButton_pressed():
	var dialog = ConfirmationDialog.new()
	get_parent().add_child(dialog)
	dialog.set_title("Are you sure?")
	dialog.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	dialog.set_exclusive(true)		
	dialog.get_cancel().connect("pressed", self, "_on_delete_cancelled")
	dialog.connect("confirmed", self, "_on_delete_confirmed")	
	dialog.popup()
	
	yield(dialog, "popup_hide")
	dialog.queue_free()

func _on_delete_cancelled():
	pass # left here for learning purposes (how to connect cancel)
	
func _on_delete_confirmed():
	DataRepository.delete_card(card)
	queue_free()
