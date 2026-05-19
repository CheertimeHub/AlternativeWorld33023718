shader_type canvas_item;

uniform float grid_size : hint_range(8.0, 128.0) = 32.0;
uniform vec4 bg_color : source_color = vec4(0.09, 0.09, 0.14, 1.0);
uniform vec4 line_color : source_color = vec4(0.18, 0.18, 0.28, 1.0);
uniform float line_width : hint_range(0.5, 4.0) = 1.0;

void fragment() {
	vec2 world_pos = UV * vec2(2560.0, 1440.0);
	vec2 grid = mod(world_pos, grid_size);
	float lx = step(grid_size - line_width, grid.x);
	float ly = step(grid_size - line_width, grid.y);
	float line = max(lx, ly);
	COLOR = mix(bg_color, line_color, line);
}
