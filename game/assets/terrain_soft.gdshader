shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform vec4 base_color : source_color = vec4(0.7,0.8,0.75,1.0);
uniform float grain = 0.04;
uniform vec4 road_bounds = vec4(0.0);
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex(){ world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 float n=noise(world_pos.xz*0.7)*0.7+noise(world_pos.xz*3.0)*0.3;
 vec3 color=base_color.rgb+(n-0.5)*grain;
 if(road_bounds.z>0.0){
  vec2 inside=road_bounds.zw-abs(world_pos.xz-road_bounds.xy);
  float edge=min(inside.x,inside.y)+(noise(world_pos.xz*1.8)-0.5)*0.9;
  float blend=smoothstep(0.03,0.7,edge);
  color=mix(vec3(0.775,0.835,0.807)+(n-0.5)*0.035,color,blend);
 }
 ALBEDO=color;
 ROUGHNESS=1.0;
}
