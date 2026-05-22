class_name LaserEscarlate
extends Node2D

## Laser da Varredura Escarlate.
## initialize() deve ser chamado ANTES de add_child() para que _ready() já tenha os dados.

signal finished
signal counter_hit

const SWEEP_SPEED: float = 150.0
const PARRY_RANGE: float = 72.0
const CONTACT_DAMAGE: float = 1800.0

var _player: Node2D
var _bus: Node
var _fire_scene: PackedScene

var _arena_left: float
var _arena_right: float
var _arena_floor: float
var _origin: Vector2

enum Phase { WARN, SWEEP, DONE }
var _phase: Phase = Phase.WARN
var _warn_timer: float = 0.4

var _sweep_x: float
var _sweep_target: float
var _sweep_dir: float

var _parry_open: bool = false
var _line: Line2D
var _counter_callable: Callable # Guardado como campo para disconnect funcionar

# Chamado ANTES de add_child — dados já disponíveis quando _ready() rodar
func initialize(
	origin: Vector2, player: Node2D,
	left: float, right: float, floor_y: float,
	fire_scene: PackedScene
) -> void:
	_origin = origin
	_player = player
	_arena_left = left
	_arena_right = right
	_arena_floor = floor_y
	_fire_scene = fire_scene


func _ready() -> void:
	global_position = _origin

	_bus = get_node("/root/EventBus")

	_line = Line2D.new()
	_line.default_color = Color(1.0, 0.08, 0.05, 0.95)
	_line.width = 6.0
	add_child(_line)

	# Guardado como campo para poder fazer disconnect depois
	_counter_callable = Callable(self, "_on_counter")
	_bus.connect("player_counter_pressed", _counter_callable)

	# Boss em qual lado? Laser começa no lado OPOSTO do chão
	var boss_left: bool = _origin.x < (_arena_left + _arena_right) * 0.5
	_sweep_x = _arena_right - 16.0 if boss_left else _arena_left + 16.0
	
	_sweep_target = _player.global_position.x if (_player != null and is_instance_valid(_player)) else (_arena_left + _arena_right) * 0.5
	_sweep_dir = sign(_sweep_target - _sweep_x)


func _physics_process(delta: float) -> void:
	if _phase == Phase.DONE:
		return

	match _phase:
		Phase.WARN:
			_warn_timer -= delta
			if _warn_timer <= 0.0:
				_phase = Phase.SWEEP
				_parry_open = true
		Phase.SWEEP:
			_tick_sweep(delta)

	_redraw_laser()


func _tick_sweep(dt: float) -> void:
	_sweep_x += _sweep_dir * SWEEP_SPEED * dt

	var reached: bool = _sweep_x >= _sweep_target if _sweep_dir > 0.0 else _sweep_x <= _sweep_target

	if reached:
		_parry_open = false
		var dashing: bool = _player.get("is_dashing") if (_player != null and is_instance_valid(_player)) else false

		if not dashing and _player != null and is_instance_valid(_player):
			_player.call("take_damage", CONTACT_DAMAGE)
			_spawn_fire(_player.global_position.x)
		
		_end()
		return

	if _sweep_x < _arena_left or _sweep_x > _arena_right:
		_end()


func _on_counter() -> void:
	if not _parry_open or _phase != Phase.SWEEP:
		return
	if _player == null or not is_instance_valid(_player):
		return

	var dist_to_beam: float = abs(_player.global_position.x - _sweep_x)
	if dist_to_beam > PARRY_RANGE:
		return

	_parry_open = false
	counter_hit.emit()
	_end()


func _redraw_laser() -> void:
	if _line == null:
		return
	_line.clear_points()
	_line.add_point(Vector2.ZERO)
	_line.add_point(Vector2(_sweep_x - _origin.x, _arena_floor - _origin.y))


func _spawn_fire(x: float) -> void:
	if _fire_scene == null:
		return
	var fire = _fire_scene.instantiate()
	get_parent().add_child(fire)
	fire.global_position = Vector2(x, _arena_floor - 12.0)


func _end() -> void:
	if _phase == Phase.DONE:
		return
	_phase = Phase.DONE
	_disconnect_counter()
	if _line != null:
		_line.clear_points()
	finished.emit()
	queue_free()


func _disconnect_counter() -> void:
	if _bus == null:
		return
	# Usa o mesmo callable guardado — is_connected funciona corretamente
	if _bus.is_connected("player_counter_pressed", _counter_callable):
		_bus.disconnect("player_counter_pressed", _counter_callable)


func _exit_tree() -> void:
	_disconnect_counter()
