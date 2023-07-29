extends Node


signal change_route_requested(next_route)

enum Routes { LOGIN, SIGNUP, BOARDS, BOARD }
enum InputFieldDialogMode {
	CREATE_LIST,
	EDIT_LIST,
	CREATE_BOARD,
	EDIT_BOARD,
	ADD_BOARD_MEMBER
}

const InputFieldDialog := preload("res://scenes/input_field_dialog.tscn")

var popup


func go_to_main_route():
	var err = get_tree().change_scene("res://scenes/main_scene.tscn")
	if err != OK:
		push_error("[scene_utils.go_to_main_route] could not change scene error code %d" % err)


func request_route_change(route : int):
	emit_signal("change_route_requested", route)


func go_to_login():
	var err = get_tree().change_scene("res://scenes/login_register.tscn")
	if err != OK:
		push_error("[scene_utils.go_to_login] could not change scene error code %d" % err)


func go_to_boards():
	emit_signal("change_route_requested", Routes.BOARDS)


func go_to_board():
	emit_signal("change_route_requested", Routes.BOARD)


func create_single_error_popup(message : String, focus_after_close : Control, parent : Node):
	if popup:
		popup.queue_free()

	popup = load("res://scenes/single_button_popup.tscn").instance()
	popup.get_node("Label").set_text(message)
	parent.add_child(popup)
	popup.popup_centered()
	popup.get_close_button().grab_focus()

	yield(popup, "tree_exited")

	if popup:
		popup.queue_free()
	popup = null
	focus_after_close.grab_focus()


func create_delete_confirm_popup(parent : Node, confirm_target : Object, binds := [], title := "Are you sure?"):
	var dialog = ConfirmationDialog.new()
	parent.add_child(dialog)
	dialog.set_title(title)
	dialog.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	dialog.set_exclusive(true)
	dialog.connect("confirmed", confirm_target, "_on_delete_confirmed", binds)
	dialog.popup()

	yield(dialog, "popup_hide")
	dialog.queue_free()


func create_input_field_dialog(mode, board, list = null):
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_and_margins_preset(Control.PRESET_WIDE, Control.PRESET_MODE_KEEP_SIZE)
	get_parent().add_child(overlay)

	var dialog = InputFieldDialog.instance()
	overlay.add_child(dialog)
	dialog.set_board(board)
	dialog.set_mode(mode)

	if list: dialog.set_list(list)
	dialog.popup()

	yield(dialog, "popup_hide")
	dialog.queue_free()
	overlay.queue_free()
