extends ColorRect

const BOARD_SCENE := preload("res://scenes/Board.tscn")
const BOARD_CARD := preload("res://scenes/BoardCard.tscn")

func _go_to_board():	
	# todo: implement me
	get_tree().change_scene("res://scenes/Board.tscn")

func _on_BoardCard_pressed():
	# todo: implement me
	_go_to_board()
