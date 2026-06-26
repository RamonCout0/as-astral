# spin_attack.gd
# Efeito do golpe pesado do player (tecla V): alto stagger, alcance grande.
# Usa Spin-attack.png como sprite-sheet vertical (7 frames de 64x32).
extends Area2D

const TEX        := preload("res://Assets/Player/Sprites/Spin-attack.png")
const FRAME_W    := 64
const FRAME_H    := 32
const FRAME_COUNT := 7
const FPS        := 16.0

var _dir     : float = 1.0      # 1 = direita, -1 = esquerda
var _stagger : float = 3500.0
var _damage  : float = 1500.0
var _reach   : float = 220.0
var _hit_ids : Dictionary = {}


func setup(dir: float, stagger: float, damage: float, reach: float) -> void:
	_dir     = -1.0 if dir < 0.0 else 1.0
	_stagger = stagger
	_damage  = damage
	_reach   = reach


func _ready() -> void:
	collision_layer = 0
	collision_mask  = 2   # boss

	# Monta o sprite-sheet (7 frames de 64x32 empilhados verticalmente).
	var sf := SpriteFrames.new()
	sf.add_animation("spin")
	sf.set_animation_loop("spin", false)
	sf.set_animation_speed("spin", FPS)
	for i in FRAME_COUNT:
		var at := AtlasTexture.new()
		at.atlas = TEX
		at.region = Rect2(0, i * FRAME_H, FRAME_W, FRAME_H)
		sf.add_frame("spin", at)

	var asp := AnimatedSprite2D.new()
	asp.sprite_frames  = sf
	asp.animation      = "spin"
	asp.flip_h         = _dir < 0.0
	asp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Estica pra cobrir o alcance (frame tem 64px de largura).
	asp.scale    = Vector2(_reach / float(FRAME_W), 2.2)
	asp.position = Vector2(_dir * _reach * 0.5, 0.0)
	add_child(asp)
	asp.play("spin")

	# Hitbox de alcance (retângulo largo à frente).
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(_reach, 70.0)
	shape.shape = rect
	shape.position = Vector2(_dir * _reach * 0.5, 0.0)
	add_child(shape)

	body_entered.connect(_on_body)

	# Pega bosses que já estão dentro do alcance no momento do golpe.
	await get_tree().physics_frame
	if is_instance_valid(self):
		for b in get_overlapping_bodies():
			_on_body(b)

	# Some quando a animação termina.
	asp.animation_finished.connect(_fade_out)


func _fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)


func _on_body(body: Node) -> void:
	if body == null or not body.is_in_group("boss"):
		return
	var id := body.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	if body.has_method("take_damage"):
		body.take_damage(_damage)
	if body.has_method("add_stagger"):
		body.add_stagger(_stagger)
