extends Node


var board : BoardModel
var file_format = ".tres"


func _init() -> void:
	name = "LocalStorage"


func _ready() -> void:
# warning-ignore:return_value_discarded
	Events.connect("boards_loaded", self, "_load_boards")
# warning-ignore:return_value_discarded
	DataRepository.connect("board_created", self, "_on_board_created")
# warning-ignore:return_value_discarded
	DataRepository.connect("board_deleted", self, "_on_board_deleted")
# warning-ignore:return_value_discarded
	DataRepository.connect("board_updated", self, "_on_data_event")
# warning-ignore:return_value_discarded
	DataRepository.connect("list_created", self, "_on_data_event")
# warning-ignore:return_value_discarded
	DataRepository.connect("list_deleted", self, "_on_data_event")
# warning-ignore:return_value_discarded
	DataRepository.connect("list_updated", self, "_on_data_event")
# warning-ignore:return_value_discarded
	DataRepository.connect("card_created", self, "_on_data_event")
# warning-ignore:return_value_discarded
	DataRepository.connect("card_deleted", self, "_on_data_event")
# warning-ignore:return_value_discarded
	DataRepository.connect("card_updated", self, "_on_data_event")

	_check_repository_exist()


func _load_boards() -> void:
	var dir = Directory.new()

	if dir.open(AppGlobal.local_repository) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()

		while file_name != "":
			var board_ = ResourceLoader.load(AppGlobal.local_repository.plus_file(file_name)) as BoardModel
			board_.user_owner = AppGlobal.local_owner
			DataRepository.add_board(board_)

			for list in board_.lists:
				DataRepository.add_list(list)

			file_name = dir.get_next()
	else:
		push_error("[local_storage._load_boards] an error occurred when trying to access %s." % AppGlobal.local_repository)


func _save_data() -> void:
	var err = ResourceSaver.save(AppGlobal.local_repository.plus_file(str(board.id,file_format)),board)

	if err != OK:
		push_error("[local_storage._save_data] couldn't save resource error %d" % err)


func _on_board_created(board_ : BoardModel) -> void:
	board = board_
	_save_data()


func _on_board_deleted(board_ : BoardModel) -> void:
	var dir = Directory.new()
	if dir.file_exists(AppGlobal.local_repository.plus_file(str(board_.id,file_format))):
		var err = dir.remove(AppGlobal.local_repository.plus_file(str(board_.id,file_format)))

		if err != OK:
			push_error("[local_storage._on_board_delted] couldn't delete resource error %d" % err)


func _on_data_event(_model) -> void:
	if DataRepository.active_board != null:
		board = DataRepository.active_board
		call_deferred("_save_data")


func _check_repository_exist() -> void:
	var dir = Directory.new()

	if !dir.dir_exists(AppGlobal.local_repository):
		var err = dir.make_dir(AppGlobal.local_repository)

		if err != OK:
			push_error("[local_storage._check_repository_exist] couldn't create directory %s error %d" % [AppGlobal.local_repository,err])
