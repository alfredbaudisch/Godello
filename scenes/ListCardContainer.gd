extends ScrollContainer

func can_drop_data(_pos, data):
	if data.model.model_type == Model.ModelTypes.CARD:
		print("IT IS A CARD, IT CAN ALSO CAN BE DROPPED")
		return true	
	
	return false

func drop_data(_pos, data):
	if data.model.model_type == Model.ModelTypes.CARD:
		print("DROPPED CARD", data.model)
