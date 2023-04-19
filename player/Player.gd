extends CharacterBody3D

signal health_changed(value)

const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const LOOK_SENSIVITY = 0.005
@onready var camera:Camera3D = $Camera3D
@onready var animationPlayer:AnimationPlayer = $AnimationPlayer
@onready var muzzleFlash:GPUParticles3D = $Camera3D/pistol/MuzzleFlash
@onready var raycast:RayCast3D = $Camera3D/RayCast3D

var health = 100

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity_y = 0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	var horizontal_velocity = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
	velocity = horizontal_velocity.x * global_transform.basis.x + horizontal_velocity.y * global_transform.basis.z
	velocity *= SPEED
	if is_on_floor():
		velocity_y = 0
		if Input.is_action_just_pressed("jump"): velocity_y = JUMP_VELOCITY
	else:
		velocity_y -= gravity * delta
	
	velocity.y = velocity_y
	
	if horizontal_velocity == Vector2.ZERO and is_on_floor():
		animationPlayer.play("idle")
	else: animationPlayer.play("move")
	
	if Input.is_action_just_pressed("shoot") and animationPlayer.current_animation != "shoot":
		play_shoot_effects.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())
	
	move_and_slide()

@rpc("call_local")
func play_shoot_effects():
	animationPlayer.stop()
	animationPlayer.play("shoot")
	muzzleFlash.restart()
	muzzleFlash.emitting = true

@rpc("any_peer")
func receive_damage():
	health -= 20
	if health <= 0:
		health = 100
		position = Vector3.ZERO
	health_changed.emit(health)

func _unhandled_input (event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * LOOK_SENSIVITY)
		camera.rotate_x(-event.relative.y * LOOK_SENSIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		animationPlayer.play("idle")
