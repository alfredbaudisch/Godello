extends Node

signal user_logged_in(user)
signal user_logged_out(user)

signal card_clicked(model)
signal card_dragged(node, model)
signal card_dropped(drop_data, into_list)

signal list_dragged(node, model)
signal list_dropped(drop_data)
signal add_card_clicked(list)

signal backend_requesting(action, is_requesting, is_global)
signal backend_response(action, is_success, body)
signal backend_error(action, should_try_again, result)

signal user_channel_joined()
signal user_channel_left()
signal board_channel_joined()
signal board_channel_left()
