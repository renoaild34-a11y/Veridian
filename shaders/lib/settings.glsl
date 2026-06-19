
#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL


#define SHADOWS_ENABLED      1      
#define SHADOW_SOFTNESS      1.5    
#define SHADOW_FILTER_SAMPLES 16    
#define SHADOW_BIAS          0.00035
#define COLORED_SHADOWS      1      
#define LEAF_SHADOWS_ENABLED 0      


#define AMBIENT_STRENGTH     0.85   
#define SUNLIGHT_STRENGTH    1.05   
#define BLOCKLIGHT_STRENGTH  1.15   
#define SPECULAR_ENABLED     1      
#define HELD_LIGHT_ENABLED   1      
#define COLORED_LIGHTS_ENABLED 1    
#define COLORED_LIGHT_SPILL_SCREENSPACE 0 


#define ATMOSPHERE_QUALITY   1      
#define SKY_BRIGHTNESS       1.0    
#define STARS_ENABLED        1      
#define MOON_ENABLED         1      


#define CLOUDS_ENABLED       1      
#define CLOUD_STEPS          32     
#define CLOUD_LIGHT_STEPS    6      
#define CLOUD_COVERAGE       0.50   
#define CLOUD_DENSITY        1.25   
#define CLOUD_HEIGHT         140.0  
#define CLOUD_THICKNESS      90.0   
#define CLOUD_SPEED          1.0    


#define VL_ENABLED           1      
#define VL_STEPS             24     
#define VL_STRENGTH          0.3    
#define FOG_ENABLED          1      
#define FOG_DENSITY          0.5    


#define WATER_WAVES          1      
#define WATER_WAVE_HEIGHT    0.045  
#define WATER_REFRACTION     1      
#define WATER_ABSORPTION     1.0    


#define SSR_ENABLED          1      
#define SSR_STEPS            24     
#define SSR_REFINE           4      


#define SSAO_ENABLED         1      
#define SSAO_SAMPLES         12     
#define SSAO_RADIUS          0.9    
#define SSAO_STRENGTH        1.0    


#define BLOOM_ENABLED        1      
#define BLOOM_STRENGTH       0.55   


#define TONEMAP              1      
#define EXPOSURE             1.0    
#define CONTRAST             1.02   
#define SATURATION           1.0    
#define VIBRANCE             0.05   
#define WHITE_BALANCE        0.0    


#define DH_FOG_BLEND         1      
#define DH_WATER_ENABLED     0      
#define DH_TERRAIN_WATER_FIX 1      

#endif 
