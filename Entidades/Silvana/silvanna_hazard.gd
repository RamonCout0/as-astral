# silvanna_hazard.gd
# Cubo de perigo genérico (PLACEHOLDER). Node2D + ColorRect, sem dependência de
# camadas de colisão — a detecção é por AABB manual contra o player.
#
# Fluxo: TELEGRAFO (cubo translúcido, sem dano) -> ATIVO (cubo sólido, dá dano) -> some.
#
# Uso:
#   var h = preload("res://Entidades/Silvana/silvanna_hazard.gd").new()
#   h.setup(size, color, damage, telegraph, active, tick, respect_dash, instakill)
#   parent.add_child(h)
#   h.global_position = pos
extends Node2D

var _size        : Vector2 = Vector2(32, 32)
var _color       : Color   = Color(1, 0, 0)
var _damage      : float   = 500.0
var _telegraph   : float   = 0.6     # tempo de aviso antes de ativar
var _active      : float   = 0.4     # tempo causando dano (-1 = permanente)
var _tick        : float   = 0.0     # 0 = dano único; >0 = dano contínuo a cada _tick s
var _respect_dash: bool    = true    # se true, dash do player anula o dano (I-frame)
var _instakill   : bool    = false

var _rect      : ColorRect = null
var _phase     : int   = 0           # 0 = telegrafo, 1 = ativo
var _timer     : float = 0.0
var _dmg_cd    : float = 0.0
var _hit_once  : bool  = false
var _player    : Node2D = null

signal expired


func setup(size: Vector2, color: Color, damage: float, telegraph: float,
		active: float, tick: float = 0.0, respect_dash: bool = true,
		instakill: bool = false) -> void:
	_size         = size
	_color        = color
	_damage       = damage
	_telegraph    = telegraph
	_active       = active
	_tick         = tick
	_respect_dash = respect_dash
	_instakill    = instakill


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D

	_rect = ColorRect.new()
	_rect.size     = _size
	_rect.position = -_size * 0.5            # centraliza no global_position
	_rect.color    = Color(_color.r, _color.g, _color.b, 0.30)  # translúcido no aviso
	add_child(_rect)

	_phase = 0
	_timer = _telegraph
	if _telegraph <= 0.0:
		_activate()


func _activate() -> void:
	_phase = 1
	_timer = _active
	if _rect:
		_rect.color = Color(_color.r, _color.g, _color.b, 0.85)


func _physics_process(delta: float) -> void:
	_dmg_cd -= delta

	if _phase == 0:
		# Pisca o telegrafo
		if _rect:
			_rect.color.a = 0.20 + 0.20 * (sin(_timer * 18.0) * 0.5 + 0.5)
		_timer -= delta
		if _timer <= 0.0:
			_activate()
		return

	# --- FASE ATIVA ---
	_try_damage()

	if _active >= 0.0:
		_timer -= delta
		if _timer <= 0.0:
			expired.emit()
			queue_free()


func _try_damage() -> void:
	if not _player or not is_instance_valid(_player):
		return

	# AABB: player dentro do cubo?
	var half := _size * 0.5
	var p := _player.global_position
	if abs(p.x - global_position.x) > half.x or abs(p.y - global_position.y) > half.y:
		return

	# I-frame de dash
	if _respect_dash and _player.get("is_dashing"):
		return

	if _instakill:
		_player.take_damage(999999.0)
		return

	if _tick <= 0.0:
		# Dano único
		if not _hit_once:
			_hit_once = true
			_player.take_damage(_damage)
	else:
		# Dano contínuo
		if _dmg_cd <= 0.0:
			_dmg_cd = _tick
			_player.take_damage(_damage)
