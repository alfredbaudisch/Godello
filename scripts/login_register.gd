extends ColorRect


const PASSWORD_MIN_LENGTH = 6

var is_sign_in := true

# As educational and illustrational purpose, in this script the `find_node` way
# of getting nodes is used.
onready var sign_up_form := $"/root/LoginRegister".find_node("SignUpForm")
onready var sign_in_form := $"/root/LoginRegister".find_node("SignInForm")
onready var first_name_input := $"/root/LoginRegister".find_node("FirstName")
onready var last_name_input := $"/root/LoginRegister".find_node("LastName")
onready var email_input := $"/root/LoginRegister".find_node("Email")
onready var password_input := $"/root/LoginRegister".find_node("Password")
onready var confirm_password_input := $"/root/LoginRegister".find_node("ConfirmPassword")
onready var login_email_input := $"/root/LoginRegister".find_node("SignInEmail")
onready var login_password_input := $"/root/LoginRegister".find_node("SignInPassword")


func _ready():
	_go_to_sign_in()


func _input(_event):
	if Input.is_action_just_released("ui_accept"):
		if is_sign_in:
			_sign_in()
		else:
			_sign_up()

	elif Input.is_action_just_released("ui_cancel"):
		if is_sign_in:
			get_tree().quit()
		else:
			_go_to_sign_in()


func _on_SignInButton_pressed():
	_sign_in()


func _on_SignUpButton_pressed():
	_sign_up()


func _on_GoToSignUpButton_pressed():
	_go_to_sign_up()


func _on_GoToSignInButton_pressed():
	_go_to_sign_in()


func _go_to_sign_up():
	is_sign_in = false
	sign_up_form.set_visible(true)
	sign_in_form.set_visible(false)


func _go_to_sign_in():
	is_sign_in = true
	sign_up_form.set_visible(false)
	sign_in_form.set_visible(true)


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
