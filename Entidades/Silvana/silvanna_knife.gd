# silvanna_knife.gd
# Projétil — Faca de Ricochete. Parâmetros vêm por meta (setados pelo boss):
#   direction, arena, speed, damage, bounces, lifetime, skin (todos opcionais).
extends Area2D

var _velocity    : Vector2
var _bounces     : int  = 0
var _time        : float = 0.0
var _arena       : Rect2 = Rect2(0, 0, 480, 270)
var _speed       : float = 380.0
var _max_bounces : int  = 3
var _lifetime    : float = 6.0
var _damage      : float = 800.0


func _ready() -> void:
	var dir : Vector2 = get_meta("direction") if has_meta("direction") else Vector2.RIGHT
	if has_meta("arena"):    _arena       = get_meta("arena")
	if has_meta("speed"):    _speed       = get_meta("speed")
	if has_meta("bounces"):  _max_bounces = get_meta("bounces")
	if has_meta("lifetime"): _lifetime    = get_meta("lifetime")
	if has_meta("damage"):   _damage      = get_meta("damage")

	_velocity = dir.normalized() * _speed
	collision_layer = 0
	collision_mask  = 1

	# Visual: skin opcional, senão cubo placeholder.
	var skin = get_meta("skin") if has_meta("skin") else null
	if skin is PackedScene:
		var s = skin.instantiate()
		add_child(s)
		if s is AnimatedSprite2D:
			s.play()
	else:
		var vis := ColorRect.new()
		vis.size     = Vector2(12.0, 4.0)
		vis.position = Vector2(-6.0, -2.0)
		vis.color    = Color(0.9, 0.9, 0.6)
		add_child(vis)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12.0, 4.0)
	shape.shape = rect
	add_child(shape)

	body_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= _lifetime:
		queue_free()
		return

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
		if _bounces >= _max_bounces:
			queue_free()
			return

	global_position += _velocity * delta
	rotation = _velocity.angle()


func _on_hit(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		if not body.get("is_dashing"):
			body.take_damage(_damage)
	queue_free()
