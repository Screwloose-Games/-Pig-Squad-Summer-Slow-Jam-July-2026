shader_type canvas_item;
// Flashes a sprite toward a solid colour on hit. modulate cannot do this on its
// own: it multiplies the texture, so it can only darken or tint, never whiten.

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;


void fragment() {
	// COLOR arrives as texture(TEXTURE, UV) * modulate * self_modulate, so mixing
	// only .rgb leaves the death animation's alpha fade intact.
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_amount);
}
