extends Node


enum Storage {LOCAL,ELIXIR}
var backend : int = Storage.LOCAL setget _set_backend	# Default setting to local
var local_repository : String = "user://repository"
var executable_path : String
var config_file_path = "user://config.cfg"
var local_owner = UserModel.new("1","Local","User")		# temporary user for local backend might add the feature of multiple local users.


func _ready() -> void:
	OS.min_window_size  = Vector2(600.0,400.0)
	executable_path = OS.get_executable_path()
	load_config()


func load_config() -> void:
	var config = ConfigFile.new()
	var err = config.load(config_file_path)

	if err != OK:
		push_error("couldn't load config file error %d" % err)
	else:
		backend = config.get_value("server","backend")
		local_repository = config.get_value("local","repository_path")
		save_config()


func save_config() -> void:
	var config = ConfigFile.new()
	config.set_value("server","backend",backend)
	config.set_value("local","repository_path",local_repository)

	var err = config.save(config_file_path)

	if err != OK:
		push_error("couldn't save config file error %d" % err)


func _set_backend(value) -> void:
	backend = value
	save_config()
