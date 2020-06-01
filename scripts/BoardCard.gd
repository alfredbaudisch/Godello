extends Button

var model : BoardModel setget set_model, get_model

onready var title_label := $Title

func _ready():
	DataRepository.connect("board_deleted", self, "_on_board_deleted")

func set_model(_model : BoardModel):
	model = _model
	title_label.set_text(model.title)

func get_model():
	return model

func _on_board_deleted(board):
	if model and board.id == model.id:
		queue_free()
