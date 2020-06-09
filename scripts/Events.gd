extends Node

signal user_logged_in(user)
signal user_logged_out(user)

signal card_clicked(model)
signal card_dragged(node, model)
signal card_dropped(drop_data, into_list)

signal list_dragged(node, model)
signal list_dropped(drop_data)
signal add_card_clicked(list)
