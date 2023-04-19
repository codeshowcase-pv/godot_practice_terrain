extends Node3D

@onready var mainMenu = $CanvasLayer/MainMenu
@onready var address = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/Address
@onready var hud = $CanvasLayer/HUD
@onready var healthBar = $CanvasLayer/HUD/HealthBar

const Player = preload("res://player/Player.tscn")
const PORT = 9999
var enetPeer = ENetMultiplayerPeer.new()

func _ready():
	hud.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func _on_host_button_pressed():
	mainMenu.hide()
	hud.show()
	enetPeer.create_server(PORT)
	multiplayer.multiplayer_peer = enetPeer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(disconnect_player)
	
	add_player(multiplayer.get_unique_id())

func _on_join_button_pressed():
	mainMenu.hide()
	hud.show()
	enetPeer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enetPeer
	
func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
	
func disconnect_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
		
func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)

func update_health_bar(value):
	healthBar.value = value
