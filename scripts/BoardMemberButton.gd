extends Button

var model : UserModel setget set_model
var board : BoardModel setget set_board

export(String) var expand_to
var normal_text

func _ready():
	normal_text = get_text()
	
func set_model(_model : UserModel):
	model = _model
	
	normal_text = Utils.get_first_character(model.first_name)
	set_text(normal_text)
	
	expand_to = model.first_name
	set_tooltip(model.get_full_name())
	
func set_board(_board : BoardModel):
	board = _board

func _on_BoardOwnerButton_gui_input(event):
	if event is InputEventMouseMotion:
		set_text(expand_to)
		$Timer.start()

func _on_Timer_timeout():
	if not Utils.is_mouse_inside_control(self):
		set_text(normal_text)
		$Timer.stop()

func _on_BoardMemberButton_pressed():
	if model and board and board.user_owner != model:
		SceneUtils.create_delete_confirm_popup(self, self, [], "Remove Board Member?")
		
func _on_delete_confirmed():
	board.remove_member(model)
