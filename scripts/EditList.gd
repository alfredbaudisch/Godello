extends ConfirmationDialog

var board : BoardModel setget set_board
var list : ListModel setget set_list

onready var input_field := $MarginContainer/TextEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	set_hide_on_ok(false)	

func _input(event):
	if event is InputEventKey and not event.is_pressed():
		match event.get_scancode():
			KEY_ESCAPE:
				hide()
				
func _on_TextEdit_gui_input(event):
	if event is InputEventKey and not event.is_pressed():
		match event.get_scancode():
			KEY_ENTER:
				save()
				
func save():
	var title = input_field.get_text().replace("\n", "").trim_suffix(" ").trim_prefix(" ")
	
	if title == "":
		SceneUtils.create_single_error_popup("List Name is required.", input_field, self)
		return
		
	if list:
		# todo: update list
		pass
	else:
		DataRepository.create_list(board, title)
	
	hide()

func set_board(_model):
	board = _model

func set_list(_model):
	list = _model
	set_title("Edit List")

func _on_EditListDialog_confirmed():
	save()

func _on_EditListDialog_about_to_show():
	yield(get_tree().create_timer(0.05), "timeout")
	input_field.grab_focus()
