#version 130

precision highp float;

//---------------------------------------------------------
// MACROS
//---------------------------------------------------------

#define EPS       0.0001
#define PI        3.14159265
#define HALFPI    1.57079633
#define ROOTTHREE 1.73205081

#define EQUALS(A,B) ( abs((A)-(B)) < EPS )
#define EQUALSZERO(A) ( ((A)<EPS) && ((A)>-EPS) )

#define ZERO4 vec4(0.0, 0.0, 0.0, 0.0)
#define ONE4  vec4(1.0, 1.0, 1.0, 1.0)

#define ZERO3 vec3(0.0, 0.0, 0.0)
#define ONE3  vec3(1.0, 1.0, 1.0)

//---------------------------------------------------------
// CONSTANTS
//---------------------------------------------------------

#define LIGHT_NUM 1

uniform float uMaxSteps;

//---------------------------------------------------------
// SHADER VARS
//---------------------------------------------------------

uniform vec3 uOffset; // TESTDEBUG

//////////////////// Camera and light uniforms
uniform vec3 uCamPos; // cam position in object space
uniform vec3 uLightP; // light position in object space
uniform vec3 uLightC; // light color

//////////////////// Volume definition uniforms
uniform sampler3D uCrust;   // 3D volume texture
uniform sampler3D uTex;   // 3D volume texture
uniform sampler3D uOcclusion;   // 3D volume texture
uniform sampler2D noiseTex;   // 2D noise texture
uniform vec3 uTexDim;     // dimensions of texture

//////////////////// Volume parameters uniforms
uniform vec3 uColor;      // color of volume
uniform float uTMK;
uniform float uTMK2;
uniform float uShininess;
uniform float uAmbient;
uniform float uBackIllum;
uniform float uMinTm;
uniform float uShadeCoeff;
uniform float uSpecCoeff;
uniform float uSpecMult;
uniform float uMisc;

//////////////////// Ray direction and position uniforms
uniform sampler2D posTex;   // ray origins    texture
uniform sampler2D dirTex;   // ray directions texture
uniform float     width_inv; // screen width inverse
uniform float     height_inv; // screen height inverse

//////////////////// Matrix uniforms
uniform mat4 inv_world_matrix;
uniform mat4 world_matrix;
uniform mat4 mvp_matrix;

float uPhi = 1.0;

/////////////////// Varying
varying vec3 vPos;

//////////////////// Step global variables
float gStepSize;
float gStepFactor;
float gSteps;
float tmk2 = uTMK2;

///// Helper Functions

bool outside(vec3 pos) 
{
    return any(greaterThan(pos, ONE3)) || any(lessThan(pos, ZERO3));
}


float rand(){
        return texture2D(noiseTex, vec2(vPos.x + vPos.z, vPos.y + vPos.z)).x;
}

float rand(vec2 co){
    return fract(sin(dot(gl_FragCoord.xy ,vec2(12.9898,78.233))) * 43758.5453);
}


bool outsideCrust(vec3 pos) {

        return (int(pos.z*11) % 2 == 0 && pos.z > 0.5);

    if(int(pos.z*10) % 2 == 0 && pos.z < 0.5) return true;

    float limit = (pos.z/1.6-0.25)*(pos.z/1.6-0.25)+(pos.x/1.7-0.25)*(pos.x/1.7-0.25)+(pos.y-0.5)*(pos.y-0.5);
    bool outr = (pos.y < 0.6 && (pos.x < 0.06 || pos.x > 0.94 ));
    return /*outr || */limit > uMisc/4.0;
}

//////// Sampling functions

float sampleVolTex(vec3 pos) 
{
        if(outsideCrust(pos)) return 0.0;

        return textureLod(uTex, pos+vec3(0.0,0.0,0.0/10.0), 0).x;
}

float sampleVolTex2(vec3 pos) 
{
        if(outsideCrust(pos)) return 0.0;

        return textureLod(uCrust, pos+vec3(0.0,0.0,0.0/10.0), 0).x;
}

float sampleVolTex3(vec3 pos) 
{
        if(outsideCrust(pos)) return 0.0;

        return textureLod(uOcclusion, pos+vec3(0.0,0.0,0.0/10.0), 0).x;
}

float sampleVolTexLower(vec3 pos) 
{
        if (outsideCrust(pos)) 
                return 0.0;

        return textureLod(uTex, pos, 1).x;
}

vec3 sampleVolTexNormal(vec3 pos) 
{
        const int lod = 1;

        float c = textureLod(uTex, pos, lod).x;

        ////////// Forward difference
        float r = textureLodOffset(uTex, pos, lod, ivec3( 1, 0, 0)).x;
        float u = textureLodOffset(uTex, pos, lod, ivec3( 0, 1, 0)).x;
        float f = textureLodOffset(uTex, pos, lod, ivec3( 0, 0, 1)).x;

        float dx = (r-c);
        float dy = (u-c);
        float dz = (f-c);

        ///////// For central difference (disabled)
        /* float l = textureLodOffset(uTex, pos, lod, ivec3(-1, 0, 0)).x; */
        /* float d = textureLodOffset(uTex, pos, lod, ivec3( 0,-1, 0)).x; */
        /* float b = textureLodOffset(uTex, pos, lod, ivec3( 0, 0,-1)).x; */

        /* float dx = (r-l); */
        /* float dy = (u-d); */
        /* float dz = (f-b); */

        if (abs(dx) < 0.1 && abs(dy) < 0.1 && abs(dz) < 0.1)
                return vec3(0,0,0);
        

        return normalize(vec3(dx,dy,dz));
}

//////// Ray marching functions


// Compute accumulated transmittance for the input ray
float getTransmittance(vec3 ro, vec3 rd) {


  //////// Step size is cuadrupled inside this function
  vec3 step = rd * gStepSize * 4.0;
  vec3 pos = ro + step;
  
  float tm = 1.0;
  
  int maxSteps = int (4.0 / gStepSize);

  float uTMK_gStepSize = -uTMK * gStepSize * 16.0;

  for (int i=0; i< maxSteps && !outside(pos) && tm > uMinTm; ++i, pos+=step) {
          float sample = sampleVolTex(pos);
          tm *= exp( uTMK_gStepSize * sample);
  }

  if (tm <= uMinTm)
          return 0.0;

  return tm;
}

// Compute accumulated transmittance for the input ray
float getTransmittanceLower(vec3 ro, vec3 rd) {


  //////// Step size is cuadrupled inside this function
  vec3 step = rd * gStepSize * 8.0;
  vec3 pos = ro + step;
  
  float tm = 1.0;
  
  int maxSteps = int (8.0 / gStepSize);

  float uTMK_gStepSize = -uTMK * gStepSize * 32.0;

  for (int i=0; i< maxSteps && !outside(pos) && tm > uMinTm; ++i, pos+=step) {
          float sample = sampleVolTexLower(pos);
          tm *= exp( uTMK_gStepSize * sample);
  }

  if (tm <= uMinTm)
          return 0.0;

  return tm;
}


// Cook-Torrance radiance
float Rs(float m,float F,vec3 N, vec3 L,vec3 V, vec3 H)
{
    float result;
    float NdotV= dot(N,V);
    float NdotH= dot(N,H);
    float NdotL= dot(N,L);
    float VdotH= dot(V,H);
    float Geom= min(min(1.0, (2.0*NdotV*NdotH)/VdotH), (2.0*NdotL*NdotH)/VdotH);
    float Rough= (1.0/(pow(m,2.0)*pow(NdotH,4.0)) * 
                  exp ( pow(NdotH,2.0)-1.0)/( pow(m,2.0)*pow(NdotH,2.0)));
    float Fresnel= F + pow(1.0-VdotH,5.0) * (1.0-F);
    return (Fresnel * Rough * Geom)/(NdotV*NdotL);
}

float getSpecularRadiance(vec3 L, vec3 V, vec3 N,float specCoeff)
{
        /* /////////// Phong //////////// */
        vec3 R = normalize(reflect(-L,N)); // Reflection vector
        float spec = dot(R,-V);
        return clamp(pow(spec, specCoeff), 0.0001, 1.0);

        /* /////////// Blinn - Phong //////////// */
        /* vec3 H = normalize(L-V);   // halfway vector */
        /* float spec = dot(normalize(H),N) * t; */
        /* if (spec < 0.01) */
        /*         return 0.0; */
        /* return pow(spec, specCoeff); */

        /* /////////// Cook-Torrence //////////// */
        /* vec3 H = normalize(L-V);   // halfway vector */
        /* return Rs(2.0, 1.0, N, -L, V, H) ; */

}

vec3 diffuseComponent(vec3 P, vec3 N, vec3 L, vec3 lCol,float ltm,float specMult, float specCoeff)
{
        float diffuseCoefficient =  uShadeCoeff + 
                pow(specCoeff * abs(dot(L,N)), specMult);

        return lCol * ltm * diffuseCoefficient;
}

vec3 ambientComponent(vec3 P, vec3 N, vec3 L, vec3 lCol,float specMult, float specCoeff)
{
        float ltm = getTransmittanceLower(P, L); // Transmittance towards light
        float ambientCoefficient =  uShadeCoeff + 
                pow(specCoeff * abs(dot(L,N)), specMult);

        return lCol * ltm * ambientCoefficient;
}

struct light_ret 
{
        vec4 col;
        vec3 first_hit;
};

light_ret raymarchLight(vec3 ro, vec3 rd, float tr) {

  light_ret ret;

  vec3 step = rd*gStepSize; // steps between samples
  vec3 pos = ro;           // sample position

  vec3 col = vec3(0.0);   // accumulated color
  float tm = 1.0;         // accumulated transmittance

  bool first = true;
  float occlusion;

  for (int i=0; i < gSteps && tm > uMinTm; ++i, pos += step) {

    vec3 L = normalize( uLightP - pos ); // Light direction
    float ltm = getTransmittance(pos, L); // Transmittance towards light

    float volSample = sampleVolTex(pos); // Density at sample point


    
    float tmk = tr;          // transmittance coefficient
    float uBackIllum2 = uBackIllum;
    vec3 sampleCol = uColor;//vec3(224.0/255.0,234/255.0,194/255.0);//uColor;
    //vec3 sampleCol2 = sampleCol;

    // crust positions
    float distance = sqrt((pos.x-0.5)*(pos.x-0.5)+(pos.y-uShininess/10.0)*(pos.y-uShininess/10.0));
    float crust = sampleVolTex2(pos)*float((pos.z<10.0/10.0 || (pos.z>10.0/10.0 && distance > uShininess/10.0)));
    //volSample+=crust;//*uMisc/10.0;

    /* If there's no mass and no back illumination, continue */
    if (volSample < 0.1/* && co<=0*/) 
            continue;

    float specMult = uSpecMult;
    float specCoeff = uSpecCoeff;
    float ambient = uAmbient;

    /// If the sample point is crust, modify the color and transmittance coefficient
    if (crust > 0) {
            tmk *= 4;
            sampleCol = vec3(186.0/255.0,112.0/255.0,76.0/255.0);
            specMult = 1.1;
            specCoeff = 0.8;
            tmk2 = 34.0;
            ambient = -0.1;
    }

    // delta transmittance
    float dtm = exp( -tmk * gStepSize * volSample);

    // accumulate transmittance
    tm *= dtm;

    vec3 diffuseColor = ZERO3;
    vec3 ambientColor = ZERO3;
    vec3 N = sampleVolTexNormal(pos);

    /////////// get diffuse contribution per light
    vec3 LK = ZERO3;
    for (int k=0; k<LIGHT_NUM; ++k) {
            vec3 L = normalize( uLightP - pos ); // Light direction
            diffuseColor += diffuseComponent(pos, N, L, uLightC,ltm,specMult,specCoeff);
    }

    ////////// get ambient contribution, simulated as light close to the view direction
    vec3 C = -normalize(rd + vec3(0.3, -0.3, 0.3));
    ambientColor = ambientComponent(pos, N, C, vec3(1.0, 1.0, 1.0),specMult,specCoeff);
    /* C = -normalize(rd + vec3(-0.3, -0.3, -0.3)); */
    /* ambientColor += ambientComponent(pos, N, C, uLightC); */

    ambientColor *= ambient;

    // Get local ambient occlusion to modulate result

    occlusion = 1.0-sampleVolTex3(pos);
    //if(uMisc > 5.0) occlusion = 1.0;

    // Accumulate color based on delta transmittance and mean transmittance
    col += (ambientColor + diffuseColor) * (1.0-dtm) * sampleCol * occlusion;

    if(ltm<uShininess/10.0) col+=(1.0-ltm)*vec3(152/255.0,95/255.0,14.0/255.0)*uBackIllum/20.0;


    // If it's the first hit, save it for depth computation
    if (first) {
            ret.first_hit = pos;
            first = false;
    }

  }



  
  float alpha = 1.0-(tm - uMinTm);
  ret.col = vec4(col, 2.0 * alpha * alpha * alpha);

  return ret;
}


void main()
{

  ///////////  
  ///////////  Retrieve ray position and direction from textures
  ///////////  
  vec2 texCoord = vec2(gl_FragCoord.x * width_inv, 1.0 - gl_FragCoord.y * height_inv);
  vec3 ro = texture2D(posTex, texCoord).xyz;
  vec4 dir  = texture2D(dirTex, texCoord);
  vec3 rd = dir.xyz;
  float rlen = dir.w;
  ///////////  ///////////  ///////////  ///////////  ///////////  

  /* gl_FragColor = vec4(ro, 1.0); */
  /* return; */


  ///////////  
  ///////////  If ray is too small, return blank fragment
  ///////////  
  if (rlen < 1e-4 || !any(greaterThan(ro, ZERO3))) {
          gl_FragDepth = gl_DepthRange.far;
          gl_FragColor = ZERO4;
          return;
  }
  ///////////  ///////////  ///////////  ///////////  ///////////  


  ///////////  
  ///////////  Set globals defining ray steps
  ///////////  
  gStepSize = ROOTTHREE / uMaxSteps;
  gStepSize *= 1.0 + (0.5-rand()) * 0.35;
  /* ro += rand() * gStepSize * 0.15; */
  gSteps = clamp(rlen / gStepSize, 1, uMaxSteps);
  ///////////  ///////////  ///////////  ///////////  ///////////  
  
  ///////////  
  /////////// Perform the raymarching
  ///////////  
  light_ret ret = raymarchLight(ro, rd, tmk2 * 2.0);
  vec4 r = ret.col;
  ///////////  ///////////  ///////////  ///////////  ///////////  


  ///////////  
  //////////// Brighten and clamp resulting color
  ///////////  
  float d = 1.0/length(uLightP-ro);
  gl_FragColor = clamp(800.0*pow(d,4.0)*vec4(0.4,0.3,0.2,0.0) +ret.col,ZERO4,ONE4);
  ///////////  ///////////  ///////////  ///////////  ///////////  

  ///////////  
  //////////// If fragment is visible, set appropiate depth
  ///////////  
  if (ret.col.a > uMinTm) {
          vec4 depth_pos = vec4(ret.first_hit, 1.0);

          /////////// Compute depth of fragment
          vec4 projPos = mvp_matrix * depth_pos;
          projPos.z /= projPos.w;
          float dfar = gl_DepthRange.far;
          float dnear = gl_DepthRange.near;
          float ddiff = gl_DepthRange.diff;
          gl_FragDepth = (ddiff * 0.5) * projPos.z + (dfar+dnear) * 0.5;
  //////////// Otherwise set max depth 
  } else {
          gl_FragDepth = gl_DepthRange.far;
  }
  ///////////  ///////////  ///////////  ///////////  ///////////  
  
}
