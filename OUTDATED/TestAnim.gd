extends Node2D

# Customizable properties
var triangle_size = 80
var grid_width = 15
var grid_height = 10
var triangles = []
var background_color = Color.WHITE # Default blue color

# Precompute spacing values
var width_spacing = triangle_size * 1.5
var height_spacing = triangle_size * sqrt(3) / 2

func _ready():
	# Create the container for all triangles
	var container = Node2D.new()
	add_child(container)
	
	# Create triangle grid
	for row in range(grid_height):
		for col in range(grid_width):
			var tri = create_triangle()
			var x_pos = col * width_spacing
			var y_pos = row * height_spacing
			
			# Offset every other row and flip every other triangle
			if row % 2 == 1:
				x_pos += width_spacing / 2
			
			# Flip alternating triangles
			tri.rotation = PI if (row + col) % 2 == 1 else 0
			
			tri.position = Vector2(x_pos, y_pos)
			container.add_child(tri)
			triangles.append(tri)
	
	# Start the animation
	start_background_animation()

func create_triangle():
	var tri = Node2D.new()
	var polygon = Polygon2D.new()
	
	# Create equilateral triangle points
	var points = PackedVector2Array()
	for i in range(3):
		var angle = i * 2 * PI / 3 - PI / 6  # Start from top point
		var point = Vector2(
			cos(angle) * triangle_size,
			sin(angle) * triangle_size
		)
		points.push_back(point)
	
	polygon.polygon = points
	polygon.color = background_color
	tri.add_child(polygon)
	
	return tri

func set_background_color(new_color: Color):
	background_color = new_color
	# Update all existing triangles
	for tri in triangles:
		var polygon = tri.get_child(0)
		polygon.color = new_color

func start_background_animation():
	# Create tween for continuous animation
	for tri in triangles:
		var tween = create_tween()
		tween.set_loops()  # Make the animation loop indefinitely
		
		# Randomize starting scale and opacity
		tri.scale = Vector2(randf_range(0.8, 1.2), randf_range(0.8, 1.2))
		var polygon = tri.get_child(0)
		polygon.color.a = randf_range(0.1, 0.4)
		
		# Create pulsing animation
		tween.tween_property(tri, "scale", 
			Vector2(randf_range(0.8, 1.2), randf_range(0.8, 1.2)), 
			randf_range(2.0, 4.0)
		).set_trans(Tween.TRANS_SINE)
		
		# Fade animation
		tween.parallel().tween_property(polygon, "color:a",
			randf_range(0.1, 0.4),
			randf_range(2.0, 4.0)
		).set_trans(Tween.TRANS_SINE)


# Add some movement to the background
func _process(delta):
	#position.x += delta * 10  # Slow drift to the right
	
	# Reset position when moved too far
	if position.x > triangle_size * 1.5:
		position.x = 0
