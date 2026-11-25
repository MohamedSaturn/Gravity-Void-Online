# PostProcessing.gd
extends Node

@onready var world_environment = $"../WorldEnvironment"

# Adjustable parameters
@export_group("Glow Settings")
@export var glow_enabled: bool = true
@export_range(0.0, 2.0) var glow_intensity: float = 0.8
@export_range(0.0, 4.0) var glow_bloom: float = 0.5
@export var glow_hdr_threshold: float = 1.0

@export_group("Color Correction")
@export_range(0.0, 2.0) var brightness: float = 1.0
@export_range(0.0, 2.0) var contrast: float = 1.0
@export_range(0.0, 2.0) var saturation: float = 1.0

@export_group("Vignette")
@export var vignette_enabled: bool = true
@export_range(0.0, 1.0) var vignette_intensity: float = 0.4

func _ready():
	update_effects()

func update_effects():
	var environment = world_environment.environment
	
	# Update Glow
	environment.glow_enabled = glow_enabled
	environment.glow_intensity = glow_intensity
	environment.glow_bloom = glow_bloom
	environment.glow_hdr_threshold = glow_hdr_threshold
	
	# Update Color Correction
	environment.adjustment_enabled = true
	environment.adjustment_brightness = brightness
	environment.adjustment_contrast = contrast
	environment.adjustment_saturation = saturation
	
