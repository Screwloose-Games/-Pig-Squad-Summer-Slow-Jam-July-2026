shader_type canvas_item;
render_mode unshaded;
// CanvasGroup variant of hit_flash.gdshader: the group merges all child sprites
// (a cut-out rig's body parts) into one buffer, so the flash and outline apply
// to the combined silhouette instead of each part — no seams at the joints.
//
// A CanvasGroup exposes its merged buffer as the *screen texture* (not TEXTURE,
// which stays unbound and reads solid white), and the data arrives premultiplied
// by alpha — hence the screen_texture sampler, the un-premultiply, and the final
// multiply into COLOR to keep modulate working, all matching CanvasGroup's
// built-in shader.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

uniform vec4 outline_color : source_color = vec4(1.0, 0.9, 0.3, 1.0);
// Outline thickness in screen pixels. 0 switches the outline off. Must stay
// under the CanvasGroup's fit_margin or the outline clips at the rect edge.
uniform float outline_width : hint_range(0.0, 16.0) = 0.0;


void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}

	c.rgb = mix(c.rgb, flash_color.rgb, flash_amount);

	if (outline_width > 0.0 && c.a < 0.5) {
		float neighbour = 0.0;
		for (int i = 0; i < 8; i++) {
			float angle = TAU * float(i) / 8.0;
			vec2 offset = vec2(cos(angle), sin(angle)) * SCREEN_PIXEL_SIZE * outline_width;
			neighbour = max(neighbour, textureLod(screen_texture, SCREEN_UV + offset, 0.0).a);
		}
		c = vec4(outline_color.rgb, outline_color.a * smoothstep(0.3, 0.7, neighbour));
	}

	COLOR *= c;
}
