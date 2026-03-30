# silvanna_knife.gd
# Projétil — Faca de Ricochete
# Instancie via PackedScene. Defina os metas "direction" e "arena" antes de add_child.
extends Area2D

const SPEED       := 380.0
const MAX_BOUNCES := 3
const LIFETIME    := 6.0

var _velocity : Vector2
var _bounces  : int  = 0
var _time     : float = 0.0
var _arena    : Rect2

func _ready() -> void:
	var dir : Vector2 = get_meta("direction", Vector2.RIGHT)
	_velocity = dir.normalized() * SPEED
	_arena    = get_meta("arena", Rect2(0, 0, 480, 270))
	collision_layer = 0
	collision_mask  = 2

	# Visual placeholder
	var vis := ColorRect.new()
	vis.size     = Vector2(12.0, 4.0)
	vis.position = Vector2(-6.0, -2.0)
	vis.color    = Color(0.9, 0.9, 0.6)
	add_child(vis)

	body_entered.connect(_on_hit)

func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= LIFETIME:
		queue_free()
		return

	# Bounce nas paredes da arena
	var next_pos := global_position + _velocity * delta
	var bounced  := false

	if next_pos.x <= _arena.position.x or next_pos.x >= _arena.position.x + _arena.size.x:
		_velocity.x = -_velocity.x
		bounced = true
	if next_pos.y <= _arena.position.y or next_pos.y >= _arena.position.y + _arena.size.y:
		_velocity.y = -_velocity.y
		bounced = true

	if bounced:
		_bounces += 1
		if _bounces >= MAX_BOUNCES:
			queue_free()
			return

	global_position += _velocity * delta
	# Rotaciona visualmente na direção do movimento
	rotation = _velocity.angle()

func _on_hit(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(800.0)
	queue_free()
