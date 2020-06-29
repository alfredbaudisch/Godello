class_name RESTBackend extends HTTPRequest

func json_post_request(url : String, body) -> int:
	var headers = ["Content-Type: application/json"]
	return request(url, headers, _use_ssl(url), HTTPClient.METHOD_POST, JSON.print(body))

func parse_json_response(body):
	return JSON.parse(body.get_string_from_utf8()).result
	
func _use_ssl(url : String) -> bool:
	return url.begins_with("https://")
