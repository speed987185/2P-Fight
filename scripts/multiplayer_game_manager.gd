extends Node2D

const LAVA_SCRIPT: Script = preload("res://scripts/lava.gd")

var player1: CharacterBody2D
var player2: CharacterBody2D
var survival_time: float = 0.0
var time_label: Label
var red_overlay: ColorRect
var victory_label: Label
var cam: Camera2D
var game_over: bool = false

func _ready() -> void:
	call_deferred("_ensure_lava_area")
	var mm = get_tree().root.get_node_or_null("MultiplayerManager")
	if not mm: 
		print("No multiplayer manager found!")
		return
		
	player1 = $"../Player1"
	player2 = $"../Player2"
	cam = $"../Camera2D"
	
	player1.owner_id = _get_peer_for_role("P1", mm)
	player1.my_role = "P1"
	if mm.player_skins.has(player1.owner_id):
		player1.apply_skin(mm.player_skins[player1.owner_id])
	player1._setup_authority()

	player2.owner_id = _get_peer_for_role("P2", mm)
	player2.my_role = "P2"
	if mm.player_skins.has(player2.owner_id):
		player2.apply_skin(mm.player_skins[player2.owner_id])
	player2._setup_authority()

	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	red_overlay = ColorRect.new()
	red_overlay.color = Color(1, 0, 0, 0)
	red_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_overlay.rect_position = Vector2.ZERO
	red_overlay.rect_size = get_viewport_rect().size
	red_overlay.visible = false
	canvas.add_child(red_overlay)
	
	time_label = Label.new()
	time_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 48)
	time_label.add_theme_color_override("font_outline_color", Color(0,0,0,1))
	time_label.add_theme_constant_override("outline_size", 8)
	time_label.text = "00:00"
	canvas.add_child(time_label)

	victory_label = Label.new()
	victory_label.set_anchors_preset(Control.PRESET_CENTER)
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.add_theme_font_size_override("font_size", 72)
	victory_label.add_theme_color_override("font_outline_color", Color(0,0,0,1))
	victory_label.add_theme_constant_override("outline_size", 12)
	victory_label.hide()
	canvas.add_child(victory_label)

func _ensure_lava_area() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return

	var lava_node: Node = parent.get_node_or_null("lava")
	if lava_node == null:
		return

	if lava_node is Area2D:
		_apply_lava_script(lava_node as Area2D)
		return

	var shape_node: CollisionShape2D = lava_node as CollisionShape2D
	if shape_node == null:
		return

	_replace_lava_shape(parent, shape_node)

func _apply_lava_script(area: Area2D) -> void:
	if area.get_script() == LAVA_SCRIPT:
		return
	area.set_script(LAVA_SCRIPT)

func _replace_lava_shape(parent: Node, shape_node: CollisionShape2D) -> void:
	var shape_resource: Shape2D = shape_node.shape
	if shape_resource == null:
		return

	var position: Vector2 = shape_node.position
	var index: int = shape_node.get_index()
	var owner_ref: Node = shape_node.owner
	var valid_owner: Node = parent
	if owner_ref != null and owner_ref.is_inside_tree() and (owner_ref == parent or owner_ref.is_ancestor_of(parent)):
		valid_owner = owner_ref

	shape_node.queue_free()

	var area: Area2D = Area2D.new()
	area.name = "lava"
	area.position = position
	area.owner = valid_owner
	area.set_script(LAVA_SCRIPT)

	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.position = Vector2.ZERO
	collision_shape.shape = shape_resource
	collision_shape.owner = valid_owner
	area.add_child(collision_shape)

	parent.add_child(area)
	parent.move_child(area, index)

func _process(delta: float) -> void:
	if not is_instance_valid(player1) or not is_instance_valid(player2):
		return

	if not game_over and (player1.dead or player2.dead):
		game_over = true
		time_label.hide()
		red_overlay.hide()
		if cam:
			cam.offset = Vector2.ZERO
		
		victory_label.show()
		var winner = 0
		if player1.dead and not player2.dead:
			victory_label.text = "Player 2 Wins!"
			victory_label.add_theme_color_override("font_color", Color(1, 0, 0))
			winner = 2
		elif player2.dead and not player1.dead:
			victory_label.text = "Player 1 Wins!"
			victory_label.add_theme_color_override("font_color", Color(0, 1, 0))
			winner = 1
		else:
			victory_label.text = "Draw!"
			victory_label.add_theme_color_override("font_color", Color(1, 1, 1))
			
		var gm = GameManager.instance
		if gm:
			gm.end_game(winner)
			
		# Make sure WinnerMenu is present
		if not has_node("WinnerMenu"):
			var winner_menu_scene = preload("res://Scenes/winner_menu.tscn")
			var menu = winner_menu_scene.instantiate()
			add_child(menu)
			
		return

	if game_over:
		return

	survival_time += delta
	var mins = int(survival_time) / 60
	var secs = int(survival_time) % 60
	time_label.text = "%02d:%02d" % [mins, secs]

	var speed_multiplier = 1.0 + (survival_time * 0.02)
	player1.speed = 1500 * speed_multiplier
	player2.speed = 1500 * speed_multiplier

	var dist = player1.global_position.distance_to(player2.global_position)
	_update_proximity_effect(dist)

func _update_proximity_effect(distance: float) -> void:
	var view_size = get_viewport_rect().size
	if red_overlay.rect_size != view_size:
		red_overlay.rect_size = view_size
	red_overlay.rect_position = Vector2.ZERO

	var trigger_distance = 900.0
	if distance < trigger_distance:
		var intensity = clamp(1.0 - (distance / trigger_distance), 0.0, 1.0)
		var blink_speed = 6.0 + intensity * 14.0
		var blink_alpha = sin(survival_time * blink_speed) * 0.5 + 0.5
		var alpha = intensity * 0.6 * blink_alpha
		red_overlay.visible = alpha > 0.01
		red_overlay.color = Color(1, 0, 0, alpha)
		if cam:
			cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity * 40.0
	else:
		red_overlay.visible = false
		red_overlay.color = Color(1, 0, 0, 0)
		if cam:
			cam.offset = Vector2.ZERO

func _get_peer_for_role(role: String, mm) -> int:
	for peer_id in mm.player_roles.keys():
		if mm.player_roles[peer_id] == role:
			return peer_id
	return 1
