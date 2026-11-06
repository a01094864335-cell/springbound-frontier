shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;
uniform float progress : hint_range(0.0,1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform int effect = 0;
uniform float density = 1.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float line_segment(vec2 p,vec2 a,vec2 b,float w){vec2 ab=b-a;return 1.0-smoothstep(w,w+0.015,length(p-a-ab*clamp(dot(p-a,ab)/dot(ab,ab),0.0,1.0)));}
void vertex(){
 vec4 center=VIEW_MATRIX*MODEL_MATRIX[3];
 vec3 scl=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
 MODELVIEW_MATRIX=mat4(vec4(scl.x,0.0,0.0,0.0),vec4(0.0,scl.y,0.0,0.0),vec4(0.0,0.0,scl.z,0.0),center);
}
void fragment(){
 vec2 p=UV*2.0-1.0;float r=length(p);float a=atan(p.y,p.x);float t=progress;float mask=0.0;float fade=sin(3.14159265*t);
 if(effect==0){ // sweeping crescent, stage progression is controlled by playback
  float sweep=-2.5+t*5.0;float delta=mod(a-sweep+9.42477796,6.2831853)-3.14159265;
  mask=(1.0-smoothstep(0.0,0.07,abs(r-0.65)))*smoothstep(-1.2,-0.1,delta)*(1.0-smoothstep(0.0,0.2,delta));
 }else if(effect==1){ // directed thrust / projectile trail
  float head=-0.8+1.6*t;mask=line_segment(p,vec2(max(-.9,head-.65),0.0),vec2(head,0.0),.025)*(1.0-smoothstep(.0,.3,abs(p.y)));
  mask+=1.0-smoothstep(.03,.12,length(p-vec2(head,0.0)));
 }else if(effect==2){ // expanding shock ring and six rays
  mask=(1.0-smoothstep(.025,.09,abs(r-(.05+.78*t))))*(1.0-t);
  mask+=pow(max(0.0,cos(a*6.0)),20.0)*(1.0-smoothstep(.12,.5,r))*fade;
 }else if(effect==3){ // restorative upward motes and gentle rings
  for(int i=0;i<12;i++){float k=float(i);vec2 c=vec2(sin(k*2.4)*.65,.8-fract(t+k/12.0)*1.6);mask+=1.0-smoothstep(.01,.06,length(p-c));}
  mask+=(1.0-smoothstep(.025,.06,abs(length(p*vec2(1.0,2.5))-(.3+.4*t))))*.35;
 }else if(effect==4){ // web spokes + concentric threads
  float spokes=pow(abs(cos(a*6.0)),70.0);float rings=1.0-smoothstep(.012,.025,abs(fract(r*5.0)-.5)/5.0);
  mask=max(spokes,rings)*(1.0-smoothstep(.65,.9,r))*smoothstep(0.0,.2,t);
 }else if(effect==5){ // powder / dust / sparks
  for(int i=0;i<24;i++){float k=float(i);float angle=k*2.39996;float speed=.2+hash(vec2(k,3.0))*.65;vec2 c=vec2(cos(angle),sin(angle))*speed*t;mask+=1.0-smoothstep(.008,.045*(1.0-t*.6),length(p-c));}
 }else if(effect==6){ // root / fungal branching, reveal from bottom
  for(int i=0;i<7;i++){float k=float(i);vec2 b=vec2(sin(k*2.5)*.8,-.7+k*.22);mask+=line_segment(p,vec2(0.0,.85),b,.015)*smoothstep(.0,.15,t-k*.09);}
 }else if(effect==7){ // status / defeat pillar
  float ellipse=length(p*vec2(1.0,2.8));mask=(1.0-smoothstep(.025,.06,abs(ellipse-.5)))*fade;
  mask+=max(0.0,1.0-abs(p.x)*8.0)*(1.0-smoothstep(.1,.9,abs(p.y)))*fade;
 }else if(effect==8){ // snow, rain, embers, leaves: periodic deterministic particles
  float clock=t*6.0;
  for(int i=0;i<48;i++){float k=float(i);float speed=.4+hash(vec2(k,4.0));vec2 c=vec2(-.95+hash(vec2(k,1.0))*1.9,.95-fract(clock*speed+k*.618)*1.9);c.x+=sin(clock+k)*.06;vec2 q=p-c;mask+=1.0-smoothstep(.006,.02*density,length(q*vec2(1.0,1.0/density)));}
 }else if(effect==9){ // layered fog and smoke, soft hashed billows
  for(int i=0;i<7;i++){float k=float(i);vec2 c=vec2(sin(k*2.4+t*6.283)*.6,cos(k*1.7+t*6.283)*.3);mask+=exp(-dot(p-c,p-c)*7.0)*.1;}
  mask*=1.0-smoothstep(.55,1.05,r);
 }else if(effect==10){ // water ripples and waves
  float phase=r*14.0-t*12.566;mask=pow(max(0.0,sin(phase)),9.0)*(1.0-smoothstep(.5,1.0,r))*.6;
 }else if(effect==11){ // flame silhouette, continuous flicker
  float width=UV.y*.4;float sway=sin(UV.y*10.0+t*37.699)*.08*(1.0-UV.y);
  mask=(1.0-smoothstep(max(.001,width*.4),max(.002,width),abs(p.x-sway)))*smoothstep(0.0,.2,UV.y)*(1.0-smoothstep(.85,1.0,UV.y));
 }
 if(effect==12){
  vec2 left=p-vec2(-.24,-.2);vec2 right=p-vec2(.24,.2);
  mask=(1.0-smoothstep(.15,.22,length(left*vec2(1.0,.5))))+(1.0-smoothstep(.15,.22,length(right*vec2(1.0,.5))));
  mask*=1.0-t;
 }
 float envelope=(effect>=8)?1.0:fade;
 ALBEDO=tint.rgb;EMISSION=tint.rgb*1.8;ALPHA=clamp(mask*envelope*tint.a,0.0,1.0);
}
