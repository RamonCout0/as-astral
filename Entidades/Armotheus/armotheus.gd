class_name Armotheus
extends CharacterBody2D

## Boss Armotheus — GDScript
## Tolerante a animações faltando: só toca a animação se ela existir no AnimatedSprite2D.

@export_group("Arena")
@export var arena_left: float = 16.0
@export var arena_right: float = 464.0
@export var arena_top: float = 16.0
@export var arena_floor: float = 252.0

const MAX_HP: float = 304000.0
const HP_PER_BAR: float = 1000.0
var _hp: float

const MAX_STAGGER: float = 5000.0
const STAGGER_DECAY: float = 80.0
const STAGGER_DRAIN_RATE: float = 1500.0
var _stagger: float

enum BossState { IDLE, PENDULO_U, LASER_ESCARLATE, STAGGERED, DEAD }
var _state: BossState = BossState.IDLE

@export var attack_cooldown: float = 3.5
var _attack_timer: float
var _last_attack: int = -1

@export var laser_scene: PackedScene
@export var fire_hazard_scene: PackedScene

var _anim: AnimatedSprite2D
var _player: Node2D
var _bus: Node

var _pend_active: bool
var _pend_t: float
var _p0: Vector2
var _p1: Vector2
var _p2: Vector2
var _pend_dmg_cd: float

var _laser_active: bool

func _ready() -> void:
	add_to_group("boss")

	_bus = get_node("/root/EventBus")
	_anim = get_node_or_null("AnimatedSprite2D")
	_player = get_tree().get_first_node_in_group("player") as Node2D

	if _player == null:
		push_warning("[Armotheus] Player não encontrado no grupo 'player'!")

	_hp = MAX_HP
	_stagger = 0.0
	_attack_timer = attack_cooldown

	global_position = Vector2((arena_left + arena_right) * 0.5, arena_top + 40.0)

	_bus.emit_signal("boss_max_health_set", MAX_HP, HP_PER_BAR)
	_bus.emit_signal("boss_stagger_updated", 0.0, MAX_STAGGER)

	_play_anim("idle")


func _physics_process(delta: float) -> void:
	if _state == BossState.DEAD:
		return

	if _state == BossState.STAGGERED:
		_stagger -= STAGGER_DRAIN_RATE * delta
		if _stagger <= 0.0:
			_stagger = 0.0
			_exit_stagger()
		_bus.emit_signal("boss_stagger_updated", _stagger, MAX_STAGGER)
		return

	_stagger = max(0.0, _stagger - STAGGER_DECAY * delta)
	_bus.emit_signal("boss_stagger_updated", _stagger, MAX_STAGGER)

	if _state == BossState.PENDULO_U:
		_tick_pendulo_u(delta)

	if not _pend_active and not _laser_active:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_launch_next_attack()


func _launch_next_attack() -> void:
	var next: int = 1 if (_last_attack == 0) else 0
	_last_attack = next
	_attack_timer = attack_cooldown

	if next == 0:
		_start_pendulo_u()
	else:
		_start_laser_escarlate()


# ── ATAQUE 1 — PÊNDULO U ─────────────────────────────────────────
func _start_pendulo_u() -> void:
	_state = BossState.PENDULO_U
	_pend_active = true
	_pend_t = 0.0
	_pend_dmg_cd = 0.0

	var from_left: bool = randf() > 0.5
	_p0 = Vector2(arena_left + 16.0 if from_left else arena_right - 16.0, arena_top + 20.0)
	_p2 = Vector2(arena_right - 16.0 if from_left else arena_left + 16.0, arena_top + 20.0)
	_p1 = Vector2((arena_left + arena_right) * 0.5, arena_floor - 8.0)

	_play_anim("attack")


func _tick_pendulo_u(dt: float) -> void:
	_pend_t += dt * 1.2
	var t: float = clamp(_pend_t, 0.0, 1.0)
	var u: float = 1.0 - t
	var pos: Vector2 = u * u * _p0 + 2.0 * u * t * _p1 + t * t * _p2

	global_position = Vector2(
		clamp(pos.x, arena_left, arena_right),
		clamp(pos.y, arena_top, arena_floor)
	)

	_pend_dmg_cd -= dt
	if _player != null and is_instance_valid(_player):
		var dashing: bool = _player.get("is_dashing")
		var dist: float = global_position.distance_to(_player.global_position)
		if not dashing and dist < 36.0 and _pend_dmg_cd <= 0.0:
			_player.call("take_damage", 2500.0)
			_pend_dmg_cd = 0.3

	if _pend_t >= 1.0:
		_pend_active = false
		_state = BossState.IDLE
		global_position = Vector2((arena_left + arena_right) * 0.5, arena_top + 40.0)
		_attack_timer = attack_cooldown
		_play_anim("idle")


# ── ATAQUE 2 — LASER ─────────────────────────────────────────────
func _start_laser_escarlate() -> void:
	_state = BossState.LASER_ESCARLATE
	_laser_active = true

	var from_left: bool = randf() > 0.5
	global_position = Vector2(
		arena_left + 16.0 if from_left else arena_right - 16.0,
		arena_top + 20.0
	)

	_play_anim("laser_warn")
	get_tree().create_timer(1.5).timeout.connect(_fire_laser)


func _fire_laser() -> void:
	if _state != BossState.LASER_ESCARLATE or laser_scene == null:
		_on_laser_finished()
		return

	_play_anim("laser_fire")

	var laser = laser_scene.instantiate()

	# Inicializa ANTES de adicionar à árvore para bater com a lógica do C#
	laser.initialize(
		global_position, _player,
		arena_left, arena_right, arena_floor,
		fire_hazard_scene
	)

	get_parent().add_child(laser)

	# Conexão de Sinais no Godot 4
	laser.finished.connect(_on_laser_finished)
	laser.counter_hit.connect(func(): add_stagger(2500.0))


func _on_laser_finished() -> void:
	_laser_active = false
	_state = BossState.IDLE
	_attack_timer = attack_cooldown
	_play_anim("idle")


# ── DANO ─────────────────────────────────────────────────────────
func take_damage(amount: float) -> void:
	if _state == BossState.DEAD or _state == BossState.STAGGERED:
		return
	_hp = max(0.0, _hp - amount)
	_bus.emit_signal("boss_health_updated", _hp)
	add_stagger(amount * 0.5)
	if _hp <= 0.0:
		_die()


# ── STAGGER ──────────────────────────────────────────────────────
func add_stagger(amount: float) -> void:
	if _state == BossState.STAGGERED or _state == BossState.DEAD:
		return
	_stagger = min(MAX_STAGGER, _stagger + amount)
	_bus.emit_signal("boss_stagger_updated", _stagger, MAX_STAGGER)
	if _stagger >= MAX_STAGGER:
		_enter_stagger()


func _enter_stagger() -> void:
	_state = BossState.STAGGERED
	_pend_active = false
	_laser_active = false
	_stagger = MAX_STAGGER
	_bus.emit_signal("boss_staggered")
	_bus.emit_signal("boss_stagger_updated", _stagger, MAX_STAGGER)
	_play_anim("staggered")


func _exit_stagger() -> void:
	_state = BossState.IDLE
	_stagger = 0.0
	_attack_timer = attack_cooldown
	_bus.emit_signal("boss_stagger_updated", 0.0, MAX_STAGGER)
	_play_anim("idle")


func _die() -> void:
	_state = BossState.DEAD
	_bus.emit_signal("boss_health_updated", 0.0)
	_play_anim("dead")
	get_tree().create_timer(1.5).timeout.connect(queue_free)


# ── HELPER ANIMAÇÃO ───────────────────────────────────────────────
func _play_anim(anim_name: String) -> void:
	if _anim == null:
		return
	if _anim.sprite_frames != null and _anim.sprite_frames.has_animation(anim_name):
		_anim.play(anim_name)
