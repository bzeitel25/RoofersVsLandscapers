extends Node

signal server_list_received(servers)
signal join_info_received(ip, port)
signal error_occurred(message)

var http_request: HTTPRequest
var master_url: String = "https://roofers-master.fly.dev" # Placeholder URL

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func register_server(server_name: String, is_private: bool, password: String, port: int) -> void:
	var data = {
		"name": server_name,
		"private": is_private,
		"password": password,
		"port": port
	}
	var query = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http_request.request(master_url + "/register", headers, HTTPClient.METHOD_POST, query)

func fetch_servers() -> void:
	http_request.request(master_url + "/list", [], HTTPClient.METHOD_GET)

func get_join_info(room_id: String, password: String = "") -> void:
	var query = "?room=" + room_id.uri_encode()
	if password != "":
		query += "&pw=" + password.uri_encode()
	http_request.request(master_url + "/join" + query, [], HTTPClient.METHOD_GET)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		error_occurred.emit("Failed to contact master server.")
		return
		
	var json = JSON.parse_string(body.get_string_from_utf8())
	if typeof(json) != TYPE_DICTIONARY:
		return
		
	if json.has("servers"):
		server_list_received.emit(json["servers"])
	elif json.has("ip") and json.has("port"):
		join_info_received.emit(json["ip"], json["port"])
	elif json.has("error"):
		error_occurred.emit(json["error"])