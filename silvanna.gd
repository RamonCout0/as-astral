extends CharacterBody2D

# ---------------------------------------------------------------------------
# ARENA
# ---------------------------------------------------------------------------
@export_group("Arena")
@export var arena_left  : float = 16.0
@export var arena_right : float = 464.0
@export var arena_top   : float = 16.0
@export var arena_floor : float = 252.0

# ---------------------------------------------------------------------------
# CONSTANTES
# ---------------------------------------------------------------------------
const MAX_HP     := 304_000.0
const HP_PER_BAR := 1_000.0

# ---------------------------------------------------------------------------
# ESTADOS
# ---------------------------------------------------------------------------
enum State {
	IDLE,
	ARMATEUS_HAT,
	STAGGERED,
	DEAD,
}

var state      : State = State.IDLE
var state_prev : State = State.IDLE

# ---------------------------------------------------------------------------
# VIDA
# ---------------------------------------------------------------------------
var current_hp : float = MAX_HP
var is_immune  : bool  = false

# ---------------------------------------------------------------------------
# ATAQUE
# ---------------------------------------------------------------------------
var attack_timer    : float = 2.0
var attack_cooldown : float = 2.5

# ---------------------------------------------------------------------------
# REFERÊNCIAS
# ---------------------------------------------------------------------------
@onready var sprite : ColorRect = $Sprite
var _player : CharacterBody2D = null

# ---------------------------------------------------------------------------
# PÊNDULO
# ---------------------------------------------------------------------------
var _pend_active : bool  = false
var _pend_t      : float = 0.0
var _pend_start  : Vector2
var _pend_end    : Vector2
var _pend_peak   : float

var _damage_cd   : float = 0.0

# =============================================================================
# INIT
# =============================================================================
func _ready() -> void:
	randomize()

	add_to_group("boss")
	_player = get_tree().get_first_node_in_group("player")

	if _player == null:
		push_warning("Player não encontrado!")

	EventBus.boss_max_health_set.emit(MAX_HP, HP_PER_BAR)

	global_position = Vector2(
		(arena_left + arena_right) * 0.5,
		arena_top + 40.0
	)

	_start_state(State.ARMATEUS_HAT)

# =============================================================================
# LOOP
# =============================================================================
func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_tick_state(delta)
	_tick_attack_cooldown(delta)

	# ❌ REMOVIDO move_and_slide()

# =============================================================================
# ESTADOS
# =============================================================================
func _start_state(new_state: State) -> void:
	state_prev = state
	state      = new_state
	attack_timer = attack_cooldown

	match new_state:
		State.ARMATEUS_HAT:
			_set_color(Color(0.6, 0.1, 0.1))
			is_immune = false

		State.STAGGERED:
			_set_color(Color(1.0, 1.0, 0.0))
			is_immune = true
			get_tree().create_timer(5.0).timeout.connect(_on_stagger_end)

		State.DEAD:
			is_immune = true
			EventBus.boss_health_updated.emit(0.0)
			get_tree().create_timer(1.0).timeout.connect(queue_free)

func _tick_state(delta: float) -> void:
	match state:
		State.ARMATEUS_HAT:
			_tick_pendulo(delta)

# =============================================================================
# COOLDOWN
# =============================================================================
func _tick_attack_cooldown(delta: float) -> void:
	if state in [State.STAGGERED, State.DEAD]:
		return
	if _pend_active:
		return

	attack_timer -= delta
	if attack_timer > 0.0:
		return

	_start_pendulo()
	attack_timer = attack_cooldown

# =============================================================================
# PÊNDULO MORTAL (VERSÃO BOA)
# =============================================================================
func _start_pendulo() -> void:
	_pend_active = true
	_pend_t      = 0.0

	var from_left := randf() > 0.5

	_pend_start = Vector2(
		arena_left + 16.0 if from_left else arena_right - 16.0,
		arena_top + 20.0
	)

	_pend_end = Vector2(
		arena_right - 16.0 if from_left else arena_left + 16.0,
		arena_top + 20.0
	)

	# 🔥 mira levemente no player
	if _player:
		_pend_end.x = clamp(_player.global_position.x, arena_left, arena_right)

	_pend_peak = arena_floor - 6.0

func _tick_pendulo(delta: float) -> void:
	if not _pend_active:
		return

	_pend_t += delta * 1.8

	var t := clamp(_pend_t, 0.0, 1.0)

	var x := lerp(_pend_start.x, _pend_end.x, t)

	# 🔥 curva agressiva
	var curve := sin(t * PI)
	curve = pow(curve, 0.6)

	var y := lerp(_pend_start.y, _pend_peak, curve)

	global_position = Vector2(x, y)

	# trava dentro da arena
	global_position.x = clamp(global_position.x, arena_left, arena_right)
	global_position.y = clamp(global_position.y, arena_top, arena_floor)

	# 🔥 dano com cooldown
	if _player and is_instance_valid(_player):
		var dist := global_position.distance_to(_player.global_position)

		_damage_cd -= delta
		if dist < 32.0 and _damage_cd <= 0.0:
			_player.take_damage(2000.0)
			_damage_cd = 0.25

	if _pend_t >= 1.0:
		_pend_active = false

		global_position = Vector2(
			(arena_left + arena_right) * 0.5,
			arena_top + 40.0
		)

# =============================================================================
# DANO
# =============================================================================
func take_damage(amount: float) -> void:
	if is_immune or state == State.DEAD:
		return

	current_hp = max(0.0, current_hp - amount)
	EventBus.boss_health_updated.emit(current_hp)

	if current_hp <= 0.0:
		_start_state(State.DEAD)

func _on_stagger_end() -> void:
	_start_state(State.ARMATEUS_HAT)

# =============================================================================
# UTIL
# =============================================================================
func _set_color(c: Color) -> void:
	if sprite:
		sprite.color = c
