# silvanna_dragon_hand.gd
# Projétil — Mão de Dragão (persegue o player; destruída por Counter).
# Pertence ao grupo "dragon_hand" para o boss limitar quantas existem ao mesmo tempo.
extends Area2D

const CHASE_CUTOFF := 1.0     # para de perseguir no último 1s (fica fácil de desviar)

# Defaults — sobrescritos por meta (setados pelo boss).
var _speed         : float = 130.0
var _lifetime      : float = 5.0
var _counter_range : float = 130.0
var _damage        : float = 1200.0

var _time : float = 0.0
var _player : Node = null
var _popped : bool = false


func _ready() -> void:
	add_to_group("dragon_hand")
	_player = get_tree().get_first_node_in_group("player")
	collision_layer = 0
	collision_mask  = 1

	if has_meta("speed"):         _speed         = get_meta("speed")
	if has_meta("lifetime"):      _lifetime      = get_meta("lifetime")
	if has_meta("counter_range"): _counter_range = get_meta("counter_range")
	if has_meta("damage"):        _damage        = get_meta("damage")

	# Visual: skin opcional (PackedScene via meta "skin"), senão cubo placeholder.
	var skin = get_meta("skin") if has_meta("skin") else null
	if skin is PackedScene:
		var s = skin.instantiate()
		add_child(s)
		if s is AnimatedSprite2D:
			s.play()
	else:
		var vis := ColorRect.new()
		vis.size     = Vector2(28.0, 20.0)
		vis.position = Vector2(-14.0, -10.0)
		vis.color    = Color(1.0, 0.4, 0.0, 0.9)
		add_child(vis)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28.0, 20.0)
	shape.shape = rect
	add_child(shape)

	body_entered.connect(_on_body_hit)
	if EventBus.has_signal("player_counter_pressed"):
		EventBus.player_counter_pressed.connect(_on_counter)


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= _lifetime:
		queue_free()
		return

	if _time < _lifetime - CHASE_CUTOFF:
		# Perseguindo
		if _player and is_instance_valid(_player):
			var dir: Vector2 = (_player.global_position - global_position).normalized()
			global_position += dir * _speed * delta
			rotation = dir.angle()
	else:
		# Últimos segundos: para e pisca (avisa que vai sumir)
		modulate.a = 0.25 + 0.45 * (sin(_time * 28.0) * 0.5 + 0.5)


func _on_body_hit(body: Node) -> void:
	if _popped:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		if not body.get("is_dashing"):
			body.take_damage(_damage)


func _on_counter() -> void:
	if _popped:
		return
	if _player and is_instance_valid(_player):
		if (_player.global_position - global_position).length() < _counter_range:
			_pop()


# Feedback de counter acertado: cresce + some, depois é destruída.
func _pop() -> void:
	_popped = true
	monitoring = false
	set_physics_process(false)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", scale * 1.7, 0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(queue_free)
