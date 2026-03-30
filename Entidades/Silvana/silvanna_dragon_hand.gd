# silvanna_dragon_hand.gd
# Projétil — Mão de Dragão (Homing, destruído apenas por Counter)
extends Area2D

const SPEED    := 180.0
const LIFETIME := 8.0

var _time : float = 0.0
var _player : Node = null

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	collision_layer = 0
	collision_mask  = 2

	# Visual placeholder — cabeça de dragão laranja
	var vis := ColorRect.new()
	vis.size     = Vector2(28.0, 20.0)
	vis.position = Vector2(-14.0, -10.0)
	vis.color    = Color(1.0, 0.4, 0.0, 0.9)
	add_child(vis)

	body_entered.connect(_on_body_hit)

	# Escuta o counter do player
	if EventBus.has_signal("player_counter_pressed"):
		EventBus.player_counter_pressed.connect(_on_counter)

func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= LIFETIME:
		queue_free()
		return

	if _player and is_instance_valid(_player):
		var dir: Vector2 = (_player.global_position - global_position).normalized()
		global_position += dir * SPEED * delta
		rotation = dir.angle()

func _on_body_hit(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1500.0)

func _on_counter() -> void:
	# Verifica se o player está próximo o suficiente para o counter ser válido
	if _player and is_instance_valid(_player):
		var dist: float = (_player.global_position - global_position).length()
		if dist < 80.0:
			queue_free()
