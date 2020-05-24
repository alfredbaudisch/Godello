extends Node

var popup

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
