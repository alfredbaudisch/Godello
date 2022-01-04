extends ColorRect


const PASSWORD_MIN_LENGTH = 6

var is_sign_in := true

export(NodePath) onready var sign_up_form = get_node(sign_up_form) as VBoxContainer
export(NodePath) onready var sign_in_form = get_node(sign_in_form) as VBoxContainer
export(NodePath) onready var sign_in_local = get_node(sign_in_local) as VBoxContainer
export(NodePath) onready var settings_panel = get_node(settings_panel) as VBoxContainer
export(NodePath) onready var settings_button = get_node(settings_button) as TextureButton
export(NodePath) onready var settings_label = get_node(settings_label) as Label
export(NodePath) onready var backend_local_button = get_node(backend_local_button) as Button
export(NodePath) onready var backend_elixir_button = get_node(backend_elixir_button) as Button
export(NodePath) onready var first_name_input = get_node(first_name_input) as LineEdit
export(NodePath) onready var last_name_input = get_node(last_name_input) as LineEdit
export(NodePath) onready var email_input = get_node(email_input) as LineEdit
export(NodePath) onready var password_input = get_node(password_input) as LineEdit
export(NodePath) onready var confirm_password_input = get_node(confirm_password_input) as LineEdit
export(NodePath) onready var login_email_input = get_node(login_email_input) as LineEdit
export(NodePath) onready var login_password_input = get_node(login_password_input) as LineEdit


func _ready():
	$VersionLabel.text = str("v ",ProjectSettings.get_setting("global/version"))
	settings_label.hide()
	_load_form()


func _input(_event):
	if Input.is_action_just_released("ui_accept"):
		if is_sign_in:
			_sign_in()
		else:
			_sign_up()

	elif Input.is_action_just_released("ui_cancel"):
		if is_sign_in and sign_in_form.visible:
			get_tree().quit()
		elif settings_panel.visible:
			settings_button.pressed = false
		else:
			_load_form()


func _on_SignInButton_pressed():
	_sign_in()


func _on_SignUpButton_pressed():
	_sign_up()


func _on_GoToSignUpButton_pressed():
	_show_form(sign_up_form)


func _on_GoToSignInButton_pressed():
	_show_form(sign_in_form)


func _load_form() -> void:
	if AppGlobal.backend == AppGlobal.Storage.LOCAL:
		backend_local_button.pressed = true
		_show_form(sign_in_local)
	elif AppGlobal.backend == AppGlobal.Storage.ELIXIR:
		backend_elixir_button.pressed = true
		_show_form(sign_in_form)


func _show_form(form) -> void:
	get_tree().set_group("login_panel","visible",false)
	yield(get_tree(),"idle_frame")
	is_sign_in = true if sign_in_form == form else false
	form.show()


func _sign_in():
	var email = Utils.clean_input_text(login_email_input.get_text())
	var password = login_password_input.get_text()

	# Basic validation
	if (
		Utils.validate_not_empty_text(email, login_email_input.get_placeholder(), login_email_input, self)
		and Utils.validate_email_field(login_email_input, self)
		and Utils.validate_not_empty_text(password, login_password_input.get_placeholder(), login_password_input, self)
	):
		print("TODO: SIGN IN!")
		SceneUtils.go_to_main_route()


func _sign_up():
	var first_name = Utils.clean_input_text(first_name_input.get_text())
	var last_name = Utils.clean_input_text(last_name_input.get_text())
	var email = Utils.clean_input_text(email_input.get_text())
	var password = password_input.get_text()
	var confirm_password = confirm_password_input.get_text()

	# Basic validation
	if (
		Utils.validate_not_empty_text(first_name, first_name_input.get_placeholder(), first_name_input, self)
		and Utils.validate_not_empty_text(last_name, last_name_input.get_placeholder(), last_name_input, self)
		and Utils.validate_not_empty_text(email, email_input.get_placeholder(), email_input, self)
		and Utils.validate_email_field(email_input, self)
		and Utils.validate_not_empty_text(password, password_input.get_placeholder(), password_input, self)
		and Utils.validate_not_empty_text(confirm_password, confirm_password_input.get_placeholder(), confirm_password_input, self)
	):
		# Password validation
		if password.length() < PASSWORD_MIN_LENGTH:
			SceneUtils.create_single_error_popup("Password must contain at least " + str(PASSWORD_MIN_LENGTH) + " characters.", password_input, self)
		elif password != confirm_password:
			SceneUtils.create_single_error_popup("Confirm password does not match Password.", confirm_password_input, self)
		# All good, sign up
		else:
			print("TODO: SIGN UP!")
			var user = UserModel.new(UUID.v4(), first_name, last_name, email)
			DataRepository.set_active_user(user)
			SceneUtils.go_to_main_route()


func _on_settings_toggled(toggle: bool) -> void:
	if toggle:
		_show_form(settings_panel)
		settings_button.modulate = Color("61bd4f")
	else:
		settings_panel.hide()
		settings_label.hide()
		settings_button.pressed = false
		settings_button.modulate = Color.white
		_load_form()


func _on_settings_mouse_entered() -> void:
	if !settings_label.visible:
		settings_label.show()
		var tween = Tween.new()
		add_child(tween)
		tween.interpolate_property(
			settings_label,
			"modulate",
			Color(1,1,1,0),
			Color(1,1,1,1),
			0.2,
			Tween.TRANS_LINEAR
		)
		tween.interpolate_property(
			settings_button,
			"rect_rotation",
			0,
			180,
			02,
			Tween.TRANS_BOUNCE,
			Tween.EASE_OUT
		)
		tween.start()
		yield(tween,"tween_all_completed")
		tween.queue_free()


func _on_settings_mouse_exited() -> void:
	if !settings_button.pressed:
		settings_label.hide()


func _on_sign_in_local_pressed() -> void:
	DataRepository.set_active_user(AppGlobal.local_owner)
	SceneUtils.go_to_main_route()


func _on_local_button_toggled(toggled: bool) -> void:
	if toggled:
		AppGlobal.backend = AppGlobal.Storage.LOCAL


func _on_elixr_button_toggled(toggled: bool) -> void:
	if toggled:
		AppGlobal.backend = AppGlobal.Storage.ELIXIR
