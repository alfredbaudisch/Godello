extends ConfirmationDialog

var board : BoardModel setget set_board
var list : ListModel setget set_list

var mode = SceneUtils.DialogMode.CREATE_LIST setget set_mode

const EMPTY_LIST_ERROR = "List Name is required."
const EMPTY_BOARD_ERROR = "Board Name is required."

const ACTION_DELETE_LIST = "delete_list"
const ACTION_DELETE_BOARD = "delete_board"

onready var input_field := $MarginContainer/TextEdit

func _ready():
	set_hide_on_ok(false)	
	
func set_mode(value):
	mode = value

	match mode:
		SceneUtils.DialogMode.EDIT_LIST:	
			add_button("Delete List", true, ACTION_DELETE_LIST)
			set_title("Edit List")
		SceneUtils.DialogMode.EDIT_BOARD:
			add_button("Delete Board", true, ACTION_DELETE_BOARD)
			set_title("Edit Board")
			input_field.set_placeholder("Board Name")

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
		SceneUtils.create_single_error_popup(
			EMPTY_BOARD_ERROR if mode == SceneUtils.DialogMode.EDIT_BOARD else EMPTY_LIST_ERROR,
			input_field, self
		)
		return
		
	match mode:
		SceneUtils.DialogMode.EDIT_LIST:	
			list.set_title(title)
			
		SceneUtils.DialogMode.EDIT_BOARD:
			board.set_title(title)
			
		SceneUtils.DialogMode.CREATE_LIST:
			DataRepository.create_list(board, title)
	
	hide()

func set_board(_model):
	board = _model
	input_field.set_text(board.title)

func set_list(_model):
	list = _model
	input_field.set_text(list.title)

func _on_EditListDialog_confirmed():
	save()

func _on_EditListDialog_about_to_show():
	yield(get_tree().create_timer(0.05), "timeout")
	input_field.grab_focus()

func _on_EditListDialog_custom_action(action):
	SceneUtils.create_delete_confirm_popup(self, self, [action])

func _on_delete_confirmed(action):
	match mode:
		SceneUtils.DialogMode.EDIT_LIST:	
			DataRepository.delete_list(list)
			hide()
			
		SceneUtils.DialogMode.EDIT_BOARD:
			# todo: delete board
			pass
