shader_type canvas_item;
// Flashes a sprite toward a solid colour on hit. modulate cannot do this on its
// own: it multiplies the texture, so it can only darken or tint, never whiten.
//
// Also draws an optional outline around the opaque silhouette (used as the
// drop-target highlight while an item is dragged over a unit). Both effects live
// in one shader because a CanvasItem takes a single material.

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

uniform vec4 outline_color : source_color = vec4(1.0, 0.9, 0.3, 1.0);
// Outline thickness in texels. 0 switches the outline off entirely.
uniform float outline_width : hint_range(0.0, 16.0) = 0.0;


void fragment() {
	// COLOR arrives as texture(TEXTURE, UV) * modulate * self_modulate, so mixing
	// only .rgb leaves the death animation's alpha fade intact.
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_amount);

	if (outline_width > 0.0) {
		float own_alpha = texture(TEXTURE, UV).a;
		if (own_alpha < 0.5) {
			// Transparent texel: if any neighbour within the width is opaque, this
			// texel sits just outside the silhouette and becomes outline.
			float neighbour = 0.0;
			for (int i = 0; i < 8; i++) {
				float angle = TAU * float(i) / 8.0;
				vec2 offset = vec2(cos(angle), sin(angle)) * TEXTURE_PIXEL_SIZE * outline_width;
				neighbour = max(neighbour, texture(TEXTURE, UV + offset).a);
			}
			COLOR = vec4(outline_color.rgb, outline_color.a * smoothstep(0.3, 0.7, neighbour));
		}
	}
}
