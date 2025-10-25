extends GPUParticles2D

@onready var body: PhysicsBody2D = get_parent()
@onready var ray_caster: RayCast2D = $RayCast2D


func _physics_process(delta: float) -> void:
	emitting = false
	
	if _tile_snow():
		var collider: Area2D = ray_caster.get_collider() as Area2D
		if collider && collider.is_in_group(&"#snow_cover"):
			emitting = true


func _tile_snow() -> bool:
	if !body || Vector2(PhysicsServer2D.body_get_state(body.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY)).is_zero_approx():
		return false
	
	var kc: KinematicCollision2D = KinematicCollision2D.new()
	body.test_move(body.global_transform, Vector2.DOWN.rotated(body.global_rotation), kc)
	if !kc.get_collider():
		return false
	
	var tile: TileMap = kc.get_collider() as TileMap
	if !tile:
		return true
	if !tile.tile_set || tile.tile_set.get_custom_data_layer_by_name(&"snow") < 0:
		return false
	
	var coord: Vector2i = tile.get_coords_for_body_rid(kc.get_collider_rid())
	for i in tile.get_layers_count():
		var tile_data: TileData = tile.get_cell_tile_data(i, coord)
		if !tile_data:
			continue
		
		if tile_data.get_custom_data(&"snow"):
			emitting = true
	
	return false
