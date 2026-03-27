extends CanvasLayer

# --- CONECTE NO INSPETOR ---
@export var bar_count_label: Label
@export var segment_progress_bar: TextureProgressBar

# Lista para o ciclo principal (Tamanho 4: Vermelho, Azul, Verde, Amarelo)
@export var cycle_textures: Array[Texture2D]

# Lista para as 3 barras finais (Tamanho 3: Quase Morto, Morrendo, Perigo Máximo)
@export var final_textures: Array[Texture2D]

# --- Variáveis Internas ---
var health_per_segment: float = 1.0
var display_health: float = 0.0
var health_tween: Tween
var total_bar_count: int = 1 # Guarda o número total de barras

func _ready():
	EventBus.boss_max_health_set.connect(set_boss_max_health)
	EventBus.boss_health_updated.connect(update_boss_health)

func set_boss_max_health(max_health, p_health_per_segment):
	health_per_segment = p_health_per_segment
	if health_per_segment <= 0: return

	segment_progress_bar.max_value = health_per_segment
	display_health = float(max_health)
	
	# Precisamos guardar o número total de barras para a nova lógica
	total_bar_count = int(ceil(float(max_health) / health_per_segment))
	
	update_hud_visuals(display_health) # Define a textura inicial
	show()

func update_boss_health(current_health):
	if health_tween and health_tween.is_running():
		health_tween.kill()

	health_tween = create_tween()
	health_tween.tween_method(update_hud_visuals, display_health, float(current_health), 1.0) # Duração de 1 segundo

# Esta é a nossa função 100% focada em VISUALIZAÇÃO
func update_hud_visuals(health_value):
	if health_per_segment <= 0: return

	# --- 1. Lógica do Texto "x" ---
	# int(ceil(...)) garante que teremos "169x" e não "169.0x"
	var current_bar_count = int(ceil(health_value / health_per_segment))
	bar_count_label.text = str(current_bar_count) + "x"

	# --- 2. LÓGICA DE SPRITE (CICLO CORRIGIDO + FASE FINAL) ---
	
	# Verifica se estamos na fase final (1 barra ou menos)
	if current_bar_count <= 1 and final_textures.size() > 0:
		# Lógica da Fase Final
		var final_index = mini(1 - current_bar_count, final_textures.size() - 1)
		if final_index >= 0:
			segment_progress_bar.texture_progress = final_textures[final_index]
	
	# Se não, usa o ciclo normal
	elif cycle_textures.size() > 0:
		# --- LÓGICA DO CICLO CORRIGIDA ---
		# (total_bar_count - current_bar_count) nos dá o número de barras perdidas.
		var cycle_index = (total_bar_count - current_bar_count) % cycle_textures.size()
		if cycle_index >= 0 and cycle_index < cycle_textures.size():
			segment_progress_bar.texture_progress = cycle_textures[cycle_index]

	# --- 3. Lógica da Barra ---
	if health_value <= 0:
		segment_progress_bar.value = 0
	else:
		var health_in_previous_bars = (current_bar_count - 1) * health_per_segment
		var current_bar_health = health_value - health_in_previous_bars
		segment_progress_bar.value = current_bar_health

	display_health = health_value
