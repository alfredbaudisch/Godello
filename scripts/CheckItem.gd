extends CheckBox

signal edit_check_item_requested(_node)

var model : TaskModel setget set_model

func set_model(_model):
  model = _model
  set_text(model.title)	
  set_pressed(model.is_done)

func _on_CheckItem_gui_input(event):
  if event is InputEventMouseButton and not event.is_pressed() and event.get_button_index() == BUTTON_RIGHT:
    emit_signal("edit_check_item_requested", self)
