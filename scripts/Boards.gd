extends ColorRect

const BOARD_SCENE := preload("res://scenes/Board.tscn")
const BOARD_CARD := preload("res://scenes/BoardCard.tscn")

func _ready():
	DataRepository.connect("board_created", self, "_on_board_created")
	# todo: load boards

func _go_to_board():	
	# todo: implement me
	get_tree().change_scene("res://scenes/Board.tscn")

func _on_BoardCard_pressed():
	# todo: implement me
	_go_to_board()

func _on_CreateBoard_pressed(is_public : bool):
	SceneUtils.create_edit_title_dialog(SceneUtils.DialogMode.CREATE_BOARD, DataRepository.get_draft_board(is_public))
	# Todo: go to created board

func _on_board_created(board : BoardModel):
	print("Got board", board)	
