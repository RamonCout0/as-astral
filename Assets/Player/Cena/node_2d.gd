extends Node2D

@export var jogador_camera: Camera2D
@export var area_limite: ReferenceRect

func _ready():
	# Isso pega as coordenadas do seu retângulo na fase e aplica na câmera do jogador
	if jogador_camera and area_limite:
		jogador_camera.limit_left = int(area_limite.global_position.x)
		jogador_camera.limit_top = int(area_limite.global_position.y)
		jogador_camera.limit_right = int(area_limite.global_position.x + area_limite.size.x)
		jogador_camera.limit_bottom = int(area_limite.global_position.y + area_limite.size.y)
