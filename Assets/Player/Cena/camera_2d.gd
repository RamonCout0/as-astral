extends Camera2D

@export var map_rect: Rect2 = Rect2(0, 0,1024, 512)  # tamanho do seu mapa

func _ready():
	make_current()

func _process(_delta):
	var half_view = get_viewport_rect().size / 2 / zoom

	# centraliza no player (o nó pai é o player)
	var target = get_parent().global_position

	# clamp pra câmera não sair do mapa
	var clamped_x = clamp(target.x, map_rect.position.x + half_view.x, map_rect.end.x - half_view.x)
	var clamped_y = clamp(target.y, map_rect.position.y + half_view.y, map_rect.end.y - half_view.y)

	global_position = Vector2(clamped_x, clamped_y)
