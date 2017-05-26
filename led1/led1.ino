#include <cpp_compat.h>
#include <dmx.h>
#include <colorpalettes.h>
#include <fastspi.h>
#include <pixeltypes.h>
#include <noise.h>
#include <chipsets.h>
#include <controller.h>
#include <fastled_progmem.h>
#include <fastled_config.h>
#include <power_mgt.h>
#include <hsv2rgb.h>
#include <fastpin.h>
#include <fastspi_types.h>
#include <fastspi_dma.h>
#include <color.h>
#include <colorutils.h>
#include <fastspi_bitbang.h>
#include <led_sysdefs.h>
#include <lib8tion.h>
#include <bitswap.h>
#include <fastspi_nop.h>
#include <fastled_delay.h>
#include <FastLED.h>
#include <platforms.h>
#include <pixelset.h>
#include <fastspi_ref.h>

#define LED_PIN     6
#define NUM_LEDS    80
#define BRIGHTNESS  64
#define LED_TYPE    WS2811
#define COLOR_ORDER GRB
CRGB leds[NUM_LEDS];

#define UPDATES_PER_SECOND 100

// This example shows several ways to set up and use 'palettes' of colors
// with FastLED.
//
// These compact palettes provide an easy way to re-colorize your
// animation on the fly, quickly, easily, and with low overhead.
//
// USING palettes is MUCH simpler in practice than in theory, so first just
// run this sketch, and watch the pretty lights as you then read through
// the code.  Although this sketch has eight (or more) different color schemes,
// the entire sketch compiles down to about 6.5K on AVR.
//
// FastLED provides a few pre-configured color palettes, and makes it
// extremely easy to make up your own color schemes with palettes.
//
// Some notes on the more abstract 'theory and practice' of
// FastLED compact palettes are at the bottom of this file.



String a;
char* subs;
byte p;
byte r;
byte g;
byte b;
bool myshow=false;
int counter = 0;

void setup() {
  Serial.begin(9600);
  
    delay( 3000 ); // power-up safety delay
    FastLED.addLeds<LED_TYPE, LED_PIN, COLOR_ORDER>(leds, NUM_LEDS).setCorrection( TypicalLEDStrip );
    FastLED.setBrightness(  BRIGHTNESS );
   for (int q=0;q<NUM_LEDS;q++){
    leds[q].r = 0;
    leds[q].g = 0;
    leds[q].b = 0;
    }
    FastLED.show();
    delay(1000/120); 
}


void loop()
{
  while (true){
  a= Serial.readString();
  //a.toCharArray(subs, 960);
  subs = a.c_str();
  char* str;
  
  
  while ((str = strtok_r(subs, ",", &subs)) != NULL){ // delimiter is the semicolon
      byte tmp;
      byte pos1=0;
      byte num=0;
      
      while (str[pos1]!=0){
          num=num*10;
          tmp=str[pos1]-'0';
          num=num+tmp;
          pos1=pos1+1;
          
        }
        Serial.println(num);
        if (counter%4==0){
          p = num;
          
        }
        if (counter%4==1){
          r = num;
          leds[p].r = r;
        }
        if (counter%4==2){
          b = num;
          leds[p].b = b;
        }
        if (counter%4==3){
          g = num;
          leds[p].g = g;
          myshow=true;
        }
        counter+=1;
        
  }
 
  if (counter>=NUM_LEDS){
     counter=0;
    Serial.println("ggg");
   FastLED.show();
   delay(1000/10);
    myshow=false;
  } 
  //Serial.println(a);
  /*
    for (int q=0;q<NUM_LEDS;q++){
    leds[q].r = 255;
    leds[q].g = 0;
    leds[q].b = 0;
    
    }
    FastLED.show();
    FastLED.delay(1000/10); 
    delay(3000);
    for (int q=0;q<NUM_LEDS;q++){
    leds[q].r = 0;
    leds[q].g = 255;
    leds[q].b = 0;
    
    }
    FastLED.show();
    FastLED.delay(1000/10); 
    delay(3000);
    for (int q=0;q<NUM_LEDS;q++){
    leds[q].r = 0;
    leds[q].g = 0;
    leds[q].b = 255;
    
    }
    FastLED.show();
    FastLED.delay(1000/10); 
    delay(3000);
*/
  }
}




