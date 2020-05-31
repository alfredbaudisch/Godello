extends Node

const EDIT_LIST_DIALOG := preload("res://scenes/EditListDialog.tscn")
enum DialogMode { CREATE_LIST, EDIT_LIST, EDIT_BOARD }

var popup

func go_to_boards():
	get_tree().change_scene("res://scenes/Boards.tscn")

func create_single_error_popup(message : String, focus_after_close : Control, parent : Node):
	if popup: popup.queue_free()
	
	popup = load("res://scenes/SingleButtonPopup.tscn").instance()
	popup.get_node("Label").set_text(message)
	parent.add_child(popup)
	popup.popup_centered()	
	popup.get_close_button().grab_focus()
	
	yield(popup, "tree_exited")
	
	if popup: popup.queue_free()
	popup = null
	focus_after_close.grab_focus()

func create_delete_confirm_popup(parent : Node, confirm_target : Object, binds := []):
	var dialog = ConfirmationDialog.new()
	parent.add_child(dialog)
	dialog.set_title("Are you sure?")
	dialog.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	dialog.set_exclusive(true)
	dialog.connect("confirmed", confirm_target, "_on_delete_confirmed", binds)	
	dialog.popup()
	
	yield(dialog, "popup_hide")
	dialog.queue_free()

func create_edit_title_dialog(mode, board, list = null):
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_and_margins_preset(Control.PRESET_WIDE, Control.PRESET_MODE_KEEP_SIZE)
	get_parent().add_child(overlay)
	
	var dialog = EDIT_LIST_DIALOG.instance()
	overlay.add_child(dialog)	
	dialog.set_board(board)
	dialog.set_mode(mode)
	
	if list: dialog.set_list(list)
	dialog.popup()
	
	yield(dialog, "popup_hide")
	dialog.queue_free()
	overlay.queue_free()
