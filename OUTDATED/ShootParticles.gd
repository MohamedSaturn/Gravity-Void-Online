extends GPUParticles2D

func _ready():
	# Basic particle setup
	amount = 20
	lifetime = 0.5
	explosiveness = 0.8
	
	# Create particle material
	var particle_material = ParticleProcessMaterial.new()
	
	# Configure particle properties
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	particle_material.spread = 45.0
	particle_material.initial_velocity_min = 100.0
	particle_material.initial_velocity_max = 200.0
	particle_material.gravity = Vector3(0, 98, 0)
	particle_material.scale_min = 2.0
	particle_material.scale_max = 4.0
	
	# Set particle color
	particle_material.color = Color(1, 0.7, 0, 1)  # Yellow-orange color
	
	# Apply material
	process_material = particle_material
	
	# Start emitting
	emitting = true
	
	# Set one-shot mode
	one_shot = true
