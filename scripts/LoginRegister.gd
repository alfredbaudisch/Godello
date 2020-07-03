extends ColorRect

const PASSWORD_MIN_LENGTH = 6

var is_login := true

# As educational and illustrational purpose, in this script the `find_node` way
# of getting nodes is used.
onready var sign_up_form := $"/root/LoginRegister".find_node("SignUpForm")
onready var login_form := $"/root/LoginRegister".find_node("LoginForm")

onready var first_name_input := $"/root/LoginRegister".find_node("FirstName")
onready var last_name_input := $"/root/LoginRegister".find_node("LastName")
onready var email_input := $"/root/LoginRegister".find_node("Email")
onready var password_input := $"/root/LoginRegister".find_node("Password")
onready var password_confirmation_input := $"/root/LoginRegister".find_node("PasswordConfirmation")
onready var login_email_input := $"/root/LoginRegister".find_node("LoginEmail")
onready var login_password_input := $"/root/LoginRegister".find_node("LoginPassword")

func _ready():
	Events.connect("user_logged_in", self, "_on_user_logged_in")
	Backend.connect("on_backend_response", self, "_on_backend_response")
	
	_go_to_login()
	
func _input(event):
	if Input.is_action_just_released("ui_accept"):
		if is_login:
			_log_in()
		else:
			_sign_up()
	
	elif Input.is_action_just_released("ui_cancel"):
		if is_login:
			get_tree().quit()
		else:
			_go_to_login()
	
func _on_LoginButton_pressed():
	_log_in()

func _on_SignUpButton_pressed():
	_sign_up()

func _on_GoToSignUpButton_pressed():
	_go_to_sign_up()
	
func _on_GoToLoginButton_pressed():	
	_go_to_login()
	
func _go_to_sign_up():
	is_login = false
	sign_up_form.set_visible(true)
	login_form.set_visible(false)
	
func _go_to_login():
	is_login = true
	sign_up_form.set_visible(false)
	login_form.set_visible(true)
	
func _log_in():
	var email = Utils.clean_input_text(login_email_input.get_text())
	var password = login_password_input.get_text()
	
	# Basic validation
	if (
		Utils.validate_not_empty_text(email, login_email_input.get_placeholder(), login_email_input, self)
		and Utils.validate_email_field(login_email_input, self)
		and Utils.validate_not_empty_text(password, login_password_input.get_placeholder(), login_password_input, self)
	):
		Backend.log_in({
			email = email,
			password = password
		})
		
		# Login vs Log in:
		# https://english.stackexchange.com/questions/5302/log-in-to-or-log-into-or-login-to
	
func _sign_up():
	var first_name = Utils.clean_input_text(first_name_input.get_text())
	var last_name = Utils.clean_input_text(last_name_input.get_text())
	var email = Utils.clean_input_text(email_input.get_text())
	var password = password_input.get_text()
	var password_confirmation = password_confirmation_input.get_text()
	
	# Basic validation
	if (
		Utils.validate_not_empty_text(first_name, first_name_input.get_placeholder(), first_name_input, self)
		and Utils.validate_not_empty_text(last_name, last_name_input.get_placeholder(), last_name_input, self)
		and Utils.validate_not_empty_text(email, email_input.get_placeholder(), email_input, self)
		and Utils.validate_email_field(email_input, self)
		and Utils.validate_not_empty_text(password, password_input.get_placeholder(), password_input, self)
		and Utils.validate_not_empty_text(password_confirmation, password_confirmation_input.get_placeholder(), password_confirmation_input, self)
	):
		# Password validation
		if password.length() < PASSWORD_MIN_LENGTH:
			SceneUtils.create_single_error_popup("Password must contain at least " + str(PASSWORD_MIN_LENGTH) + " characters.", password_input, self)			
		elif password != password_confirmation:
			SceneUtils.create_single_error_popup("Confirm password does not match Password.", password_confirmation_input, self)			
		
		# All good, sign up
		else:
			Backend.sign_up({
				first_name = first_name,
				last_name = last_name,
				email = email,
				password = password,
				password_confirmation = password_confirmation
			})

func _on_backend_response(action : int, is_success : bool, body):
	if not is_success:
		return
		
	match action:
		Backend.BackendAction.SIGN_UP, Backend.BackendAction.LOG_IN:
			var user = body["user"]
			var model = UserModel.new(user["id"], user["first_name"], user["last_name"], user["email"], body["token"])
			DataRepository.set_active_user(model)

func _on_user_logged_in(_user):
	SceneUtils.go_to_main_route()
