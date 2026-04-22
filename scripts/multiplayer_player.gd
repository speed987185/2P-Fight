extends CharacterBody2D

class_name MultiplayerPlayer

var speed: float = 1500
var jump_force: float = -2000
var gravity: float = 4000
var attacking: bool = false
var attack_cooldown: float = 0.0
var opponent: CharacterBody2D = null

var dead: bool = false

var footstep_sfx: AudioStreamPlayer
var hit_sfx: AudioStreamPlayer
var loss_sfx: AudioStreamPlayer
var jump_sfx: AudioStreamPlayer

var owner_id = 1
var my_role = "P1"

func _setup_authority():
	set_multiplayer_authority(owner_id)
	$PlayerIndicator.text = my_role + "\n▼"

func apply_skin(skin_id: int) -> void:
	var tex_path = "res://assets/player/improved/s.png"
	if skin_id == 1: tex_path = "res://assets/player/improved/s_b.png"
	elif skin_id == 2: tex_path = "res://assets/player/improved/s_p.png"
	elif skin_id == 3: tex_path = "res://assets/player/improved/s_y.png"
	
	var tex = load(tex_path)
	if not tex: return
	
	var new_frames = $AnimatedSprite2D.sprite_frames.duplicate(true)
	for anim_name in new_frames.get_animation_names():
		for i in range(new_frames.get_frame_count(anim_name)):
			var old_tex = new_frames.get_frame_texture(anim_name, i)
			if old_tex is AtlasTexture:
				var new_tex = old_tex.duplicate(true)
				new_tex.atlas = tex
				new_frames.set_frame(anim_name, i, new_tex, new_frames.get_frame_duration(anim_name, i))
	
	$AnimatedSprite2D.sprite_frames = new_frames

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	
	footstep_sfx = AudioStreamPlayer.new()
	footstep_sfx.stream = preload("res://assets/Sfx/footstep.mp3")
	footstep_sfx.bus = "SFX"
	add_child(footstep_sfx)
	
	hit_sfx = AudioStreamPlayer.new()
	hit_sfx.stream = preload("res://assets/Sfx/hitting_fixed.wav")
	hit_sfx.volume_db = -2.0
	hit_sfx.bus = "SFX"
	add_child(hit_sfx)
	
	loss_sfx = AudioStreamPlayer.new()
	loss_sfx.stream = preload("res://assets/Sfx/lossing_fixed.wav")
	loss_sfx.volume_db = -1.5
	loss_sfx.bus = "SFX"
	add_child(loss_sfx)
	
	jump_sfx = AudioStreamPlayer.new()
	jump_sfx.stream = preload("res://assets/Sfx/new jump.mp3")
	jump_sfx.volume_db = -1.5
	jump_sfx.bus = "SFX"
	add_child(jump_sfx)

	_sync_back_area_position($AnimatedSprite2D.flip_h)

func _physics_process(delta: float) -> void:
	if dead: return
	
	if attack_cooldown > 0:
		attack_cooldown -= delta

	if not is_on_floor():
		velocity.y += gravity * delta

	# Only the player who owns this character can control it
	var dir: float = 0.0
	if is_multiplayer_authority():
		# In network multiplayer, the local player always uses WASD (p1 keys) to control their character
		dir = Input.get_action_strength("p1_right") - Input.get_action_strength("p1_left")
		if Input.is_action_just_pressed("p1_jump") and is_on_floor():
			velocity.y = jump_force
			jump_sfx.stop()
			jump_sfx.play()
		if Input.is_action_just_pressed("p1_attack") and not attacking and attack_cooldown <= 0:
			attack()
				
		velocity.x = dir * speed
		
		# Sync position and velocity to other clients via RPC
		rpc("sync_movement", position, velocity, attacking, $AnimatedSprite2D.flip_h)
	
	if abs(velocity.x) > 10.0:
		var facing_left: bool = velocity.x < 0
		if $AnimatedSprite2D.flip_h != facing_left:
			$AnimatedSprite2D.flip_h = facing_left
			_sync_back_area_position(facing_left)

	move_and_slide()
	update_anim(dir)

@rpc("any_peer", "unreliable", "call_local")
func sync_movement(pos: Vector2, vel: Vector2, is_attacking: bool, flip: bool):
	if not is_multiplayer_authority():
		position = pos
		velocity = vel
		attacking = is_attacking
		$AnimatedSprite2D.flip_h = flip
		_sync_back_area_position(flip)

func update_anim(_dir: float) -> void:
	if dead or attacking: return

	if abs(velocity.x) > 0.1:
		_play_animation("run")
		if is_on_floor():
			if not footstep_sfx.playing: footstep_sfx.play()
		else:
			footstep_sfx.stop()
	elif not is_on_floor():
		_play_animation("jump")
		footstep_sfx.stop()
	else:
		_play_animation("idle")
		footstep_sfx.stop()

func _play_animation(anim_name: String) -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	if sprite.animation != anim_name or not sprite.is_playing():
		sprite.play(anim_name)

func attack() -> void:
	attacking = true
	attack_cooldown = 1.0
	$AnimatedSprite2D.play("hit")
	hit_sfx.stop()
	hit_sfx.play()

	if opponent != null and is_instance_valid(opponent):
		var opponent_backarea: Area2D = opponent.get_node("backarea")
		var hitbox_area: Area2D = $Hitbox
		var overlapping_areas: Array = hitbox_area.get_overlapping_areas()
		if opponent_backarea in overlapping_areas:
			if is_multiplayer_authority():
				opponent.rpc("die")

	await get_tree().create_timer(0.6).timeout
	attacking = false

@rpc("any_peer", "call_local", "reliable")
func die() -> void:
	if dead: return
	dead = true
	loss_sfx.play()
	footstep_sfx.stop()
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("hurt")
	
	await get_tree().create_timer(1.0).timeout
	var gm: GameManager = GameManager.instance
	if gm != null:
		var winner = 2 if my_role == "P1" else 1
		gm.end_game(winner)

func _sync_back_area_position(facing_left: bool) -> void:
	$backarea.position.x = 0
	if facing_left:
		$backarea/CollisionShape2D.position.x = 18
		$Hitbox/CollisionShape2D.position.x = -15
	else:
		$backarea/CollisionShape2D.position.x = -18
		$Hitbox/CollisionShape2D.position.x = 15

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "backarea" and area.get_parent() != self:
		opponent = area.get_parent()

func _on_hitbox_area_exited(area: Area2D) -> void:
	if area.name == "backarea" and area.get_parent() != self:
		if opponent == area.get_parent():
			opponent = null
