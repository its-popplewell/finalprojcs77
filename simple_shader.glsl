// The following defines a vertex shader main function
@vs vs
in vec4 position;
in vec4 color0;
in vec2 texcoord;

out vec4 color;
out vec2 uv;

// You can add more functions here

void main() {
    gl_Position = position;
    color = color0;
    uv = vec2(texcoord.x, 1-texcoord.y);
}
@end

// The following defines a fragment shader main function
@fs fs
uniform texture2D tex;
uniform sampler smp;

in vec4 color;
in vec2 uv;
out vec4 frag_color;

// You can add more functions here

void main() {
    //frag_color = color;
    frag_color= texture(sampler2D(tex, smp), uv);
}
@end

// The value after `@program` and before `vs fs` decide a part of the name
// of the C function you need to define in V. The value entered is suffixed `_shader_desc`
// in the generated C code. Thus the name for this becomes: `simple_shader_desc`.
// In V it's signature then need to be defined as:
// `fn C.simple_shader_desc(gfx.Backend) &gfx.ShaderDesc`. See `simple_shader.v` for the define.
//
// Running `v shader -v .` in this dir will also show you brief information
// about how to use the compiled shader.
@program simple vs fs
