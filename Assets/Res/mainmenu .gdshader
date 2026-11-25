shader_type canvas_item;

uniform vec2 speed = vec2(-0.2, -0.2);

void fragment() {
    vec2 shifted_uv = UV + (TIME * speed);
    
    // Multiply the texture color by COLOR to apply the Modulate value
    COLOR = texture(TEXTURE, shifted_uv) * COLOR;
}