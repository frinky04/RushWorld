shader_solid_white = love.graphics.newShader [[
vec4 effect(vec4 vcolor, Image tex, vec2 texcoord, vec2 pixcoord)
{
    vec4 outputcolor = Texel(tex, texcoord) * vcolor;
    outputcolor.rgb += vec3(1.0);
    return outputcolor;
}
]]
