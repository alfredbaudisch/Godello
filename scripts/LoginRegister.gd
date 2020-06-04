extends ColorRect

const PASSWORD_MIN_LENGTH = 6

# As educational and illustrational purpose, in this script the `find_node` way
# of getting nodes is used.
onready var full_name_input := $"/root/LoginRegister".find_node("FullName")
onready var email_input := $"/root/LoginRegister".find_node("Email")
onready var password_input := $"/root/LoginRegister".find_node("Password")
onready var confirm_password_input := $"/root/LoginRegister".find_node("ConfirmPassword")

func _on_SignUpButton_pressed():
	var full_name = Utils.clean_input_text(full_name_input.get_text())
	var email = Utils.clean_input_text(email_input.get_text())
	var password = password_input.get_text()
	var confirm_password = confirm_password_input.get_text()
	
	# Basic validation
	if (
		Utils.validate_not_empty_text(full_name, full_name_input.get_placeholder(), full_name_input, self)
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
			print("SIGN UP!")
