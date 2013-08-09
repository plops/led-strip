// i found this on the net

//============================================================================
// Name        : passiveSerial.cpp
// Author      : Bryan Richmond
// Version     :
// Copyright   :
// Description : Morph-ic II libftdi fpga programmer
//============================================================================
// gcc passiveSerial.c -L/usr/local/lib -lftdi1 --std=c99 -O2 -ggdb -Wall -Wextra
#include <stdio.h>
#include <libftdi1/ftdi.h>
#include <sys/stat.h>
#include <string.h>
#include <time.h>

#include <stdlib.h>

//using namespace std;

#define false 0

//Bitbang Pin Information
#define DCLK        0x01 //Bitbang Pin #1 (DCLK)
#define DATA0       0x02 //Bitbang Pin #2 (DATA0)
#define NCONFIG     0x04 //Bitbang Pin #3 (NCONFIG)
#define NSTATUS     0x08 //Bitbang Pin #4 (NSTATUS)
#define NCONF_DONE  0x10 //Bitbang Pin #5 (NCONF_DONE)

//s = source byte
//b = bool (1,0)
#define SET_DCLK(s,b)    (s |= (b << 0))
#define SET_DATA0(s,b)   (s |= (b << 1))
#define SET_NCONFIG(s,b) (s |= (b << 2))

#define CLEAR_DCLK(s)    (s &= ~(1 << 0))
#define CLEAR_DATA0(s)   (s &= ~(1 << 1))
#define CLEAR_NCONFIG(s) (s &= ~(1 << 2))

//Connection Information
#define VID 0x0403 //Vender ID
#define PID 0x6010 //Product ID

//buffers used for normal communications
//dynamic buffer declared in function used to send fpga image
unsigned char byOutputBuffer[1024];
unsigned char byInputBuffer[1024];
long dwNumBytesToSend = 0;
long dwNumBytesToRead = 0;
long dwNumBytesSent = 0;
long dwNumBytesRead = 0;


int initFTDI(struct ftdi_context * ftdic);
int startConfig(struct ftdi_context * ftdic);
int loadProgram(struct ftdi_context * ftdic);

void perror2(struct ftdi_context * ftdic)
{
	fprintf(stderr,"%s\n",ftdi_get_error_string(ftdic));
}

char*file;//="/dev/shm/test.rbf";

int main(int argc,char**argv) {
	int ret=0;
	struct ftdi_context ftdic;
	
	if(argc!=2){
	  printf("usage: upload_morphic file.rbf\n");
	  return -1;
	}
	file = argv[1];

	ftdi_init(&ftdic);

	initFTDI(&ftdic);

	startConfig(&ftdic);

	loadProgram(&ftdic);

	//reset the ftdi chip to go back into its normal mode
	if ((ret = ftdi_set_bitmode( &ftdic, 0x00, BITMODE_RESET )) < 0 )
	{
		fprintf(stderr, "can't set bitmode to %x: %d (%s)\n", BITMODE_RESET, ret, ftdi_get_error_string(&ftdic));
		fprintf( stderr, "RESET\n" );
		return EXIT_FAILURE;
	}
	ftdi_usb_close(&ftdic);
	ftdi_deinit(&ftdic);
	return 0;
}

int initFTDI(struct ftdi_context * ftdic)
{
	unsigned char Mask = 0x07;
	int ret=0;

	fprintf(stderr,"start init\n");

	//needed for multi-channel ftdi chips eg(ft2232)
	if(ftdi_set_interface(ftdic,INTERFACE_B))
		perror2(ftdic);

	if((ret = ftdi_usb_open(ftdic, VID, PID)) < 0){
		fprintf(stderr, "unable to open ftdi device: %d (%s)\n", ret, ftdi_get_error_string(ftdic));
		return EXIT_FAILURE;
	}
	if(ftdi_usb_reset(ftdic))
		perror2(ftdic);

	if(ftdi_usb_purge_buffers(ftdic)) //clean buffers
		perror2(ftdic);

	if(ftdi_write_data_set_chunksize(ftdic,65536)) //64k transfer size
		perror2(ftdic);

	if(ftdi_read_data_set_chunksize(ftdic,4096)) //64k transfer size
		perror2(ftdic);

	if(ftdi_set_event_char(ftdic,false,0)) //disable event chars
		perror2(ftdic);

	if(ftdi_set_error_char(ftdic,false,0)) //disable error chars
		perror2(ftdic);

	if(ftdi_set_latency_timer(ftdic,1)) //Set the latency timer to 1mS (default is 16mS)
		perror2(ftdic);

	if(ftdi_set_baudrate(ftdic,921600)) //highest I could go before crashing...not to sure what to put here
		perror2(ftdic);

	if(ftdi_setflowctrl(ftdic,SIO_RTS_CTS_HS)) //set flow control
			perror2(ftdic);



	if ((ret = ftdi_set_bitmode( ftdic, 0x00, BITMODE_RESET )) < 0 )
	{
		fprintf(stderr, "can't set bitmode to %x: %d (%s)\n", BITMODE_RESET, ret, ftdi_get_error_string(ftdic));
		fprintf( stderr, "RESET\n" );
		return EXIT_FAILURE;
	}
	if ((ret = ftdi_set_bitmode( ftdic, Mask, BITMODE_BITBANG )) < 0 )
	{
		fprintf(stderr, "can't set bitmode to %x: %d (%s)\n", BITMODE_BITBANG, ret, ftdi_get_error_string(ftdic));
		fprintf( stderr, "RESET\n" );
		return EXIT_FAILURE;
	}
	if(ret < 0)
		perror2(ftdic);

	fprintf(stderr,"end init\n");

	return ret;
}

int startConfig(struct ftdi_context * ftdic)
{
	unsigned char InputByte = 0;//just reading 1 byte
	fprintf(stderr,"start config\n");
	int ret=0;
	dwNumBytesToSend = 0;
	//Reset of the device
	byOutputBuffer[dwNumBytesToSend++] = 0x00;
	//NCONFIG need to go from low to low to high to initialize fpga configuration
	byOutputBuffer[dwNumBytesToSend++] = NCONFIG;

	if((dwNumBytesSent = ftdi_write_data(ftdic,byOutputBuffer,dwNumBytesToSend)) < 0)
		perror2(ftdic);

	if((ret = ftdi_read_pins(ftdic,&InputByte))<0)
		perror2(ftdic);
	//wait for ready to configure status flag from fpga
	while(!(InputByte & NSTATUS))
	{
		if((ret = ftdi_read_pins(ftdic,&InputByte))<0)
			perror2(ftdic);
	}
	if(ret < 0)
		perror2(ftdic);
	fprintf(stderr,"end config\n");
	return ret;
}



int loadProgram(struct ftdi_context * ftdic)
{
	unsigned char InputByte = 0;
	struct stat st;
	int ret=0;
	unsigned char bytebuf = 0x00;
	unsigned char * newdata;
	FILE *fp;
     
	fp=fopen(file, "r");
	stat(file,&st);
	int size = st.st_size;

	fprintf(stderr,"Size of image: %d\n",size);
	//8 bits in each byte, 3 bytes need to send each bit
	int dataSize = size*8*3;

	//create buffer large enough to store byte stream to load fpga image
	newdata = (unsigned char *)malloc(dataSize);

	int byte = 0;

	//keep NCONFIG high through out stream process
	SET_NCONFIG(bytebuf,1);

	//initialize clock bit to 0
	CLEAR_DCLK(bytebuf);

	fprintf(stderr,"data building\n");
	while((byte = fgetc(fp))!=EOF)
	{
		//for 8 bits in each byte
		for(int i = 0; i < 8; i++)
		{
			//grab data bit from right most bit, least significant bit order.
			SET_DATA0(bytebuf,(byte & 0x01));
			newdata[dwNumBytesToSend++]=bytebuf;

			//set clock bit to 1
			SET_DCLK(bytebuf,1);
			newdata[dwNumBytesToSend++]=bytebuf;

			//clear clock bit
			CLEAR_DCLK(bytebuf);
			newdata[dwNumBytesToSend++]=bytebuf;

			//clear data bit
			CLEAR_DATA0(bytebuf);

			//shift current byte to the right
			byte >>= 1;
		}
	}
	fprintf(stderr,"data packaged\n");

	fprintf(stderr,"Total bytes to send: %ld\n", dwNumBytesToSend);
	//send data

	if((dwNumBytesSent = ftdi_write_data(ftdic,newdata,dwNumBytesToSend))<0)
		perror2(ftdic);
	fprintf(stderr,"wait for confirmation\n");
	if((ret = ftdi_read_pins(ftdic,&InputByte))<0)
		perror2(ftdic);
	//wait for confirmation from fpga
	while(!(InputByte & NCONF_DONE))
	{
		if((ret = ftdi_read_pins(ftdic,&InputByte))<0)
		{
			perror2(ftdic);
			break;
		}
	}
	fprintf(stderr,"Total bytes sent: %ld\n", dwNumBytesSent);
	if(ret < 0)
		perror2(ftdic);

	//clean up
	free(newdata);
	fclose(fp);
	return ret;
}
