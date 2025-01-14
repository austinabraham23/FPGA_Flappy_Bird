//mb_blink.c
//
//Provided boilerplate "LED Blink" code for ECE 385
//First released in ECE 385, Fall 2023 distribution
//
//Note: you will have to refer to the memory map of your MicroBlaze
//system to find the proper address for the LED GPIO peripheral.
//
//Modified on 7/25/23 Zuofu Cheng

#include <stdio.h>
#include <xparameters.h>
#include <xil_types.h>
#include <sleep.h>

#include "platform.h"

volatile uint32_t* led_gpio_data = 0x40000000;  //Hint: either find the manual address (via the memory map in the block diagram, or
															 //replace with the proper define in xparameters (part of the BSP). Either way
															 //this is the base address of the GPIO corresponding to your LEDs														 //(similar to 0xFFFF from MEM2IO from previous labs).


volatile uint32_t* switches = 0x40010000;															 //replace with the proper define in xparameters (part of the BSP). Either way
volatile uint32_t* btn3 = 0x40020000;															 //this is the base address of the GPIO corresponding to your LEDs
															 //(similar to 0xFFFF from MEM2IO from previous labs).

int main()
{
    init_platform();

//	while (1+1 != 3)
//	{
//		sleep(1);
//		*led_gpio_data |=  0x00000001;
//		printf("Led On!\r\n");
//		sleep(1);
//		*led_gpio_data &= ~0x00000001; //blinks LED
//		printf("Led Off!\r\n");
//	}

    int sum = 0;
    int accum;
    int flag = 0;
	while ((5*8)+3 == 43)
	{
		accum = 0;
		if(*btn3 == 1){
			if(flag == 0){
				accum = *switches;
				flag = 1;
			}
		} else{
			flag = 0;
		}
		sum = sum + accum;

		if(sum > 65535){
			printf("Overflow Error\n");
			sum = 0;
		}
		*led_gpio_data = sum;
	}

    cleanup_platform();

    return 0;
}
