// i modified a libftdi example to switch the ftdi chip into ft245
// mode and send data. apparently the ft2232h must be configured for
// ft245 on channels A and B in the eeprom. fortunately mine was
// already set up correctly.

// gcc my.c -o my -lftdi1 --std=c99

#include <stdio.h>
#include <stdlib.h>
#include <libftdi1/ftdi.h>
#include <unistd.h>

int main(void)
{
    int ret;
    struct ftdi_context *ftdi;
    if ((ftdi = ftdi_new()) == 0)
   {
        fprintf(stderr, "ftdi_new failed\n");
        return EXIT_FAILURE;
    }

   if (ftdi_set_interface(ftdi, INTERFACE_A) < 0)
   {
       fprintf(stderr, "ftdi_set_interface failed\n");
       ftdi_free(ftdi);
       return EXIT_FAILURE;
   }
   
    if ((ret = ftdi_usb_open(ftdi, 0x0403, 0x6010)) < 0)
    {
        fprintf(stderr, "unable to open ftdi device: %d (%s)\n", ret, ftdi_get_error_string(ftdi));
        ftdi_free(ftdi);
        return EXIT_FAILURE;
    }


   /* A timeout value of 1 results in may skipped blocks */
   if(ftdi_set_latency_timer(ftdi, 2))
   {
       fprintf(stderr,"Can't set latency, Error %s\n",ftdi_get_error_string(ftdi));
       ftdi_usb_close(ftdi);
       ftdi_free(ftdi);
       return EXIT_FAILURE;
   }
   

   ftdi_set_bitmode(ftdi,0xff,BITMODE_RESET);
   ftdi_usb_purge_buffers(ftdi);
   ftdi_set_bitmode(ftdi,0xff,BITMODE_SYNCFF);

   unsigned char buf[768];
   /* for(int j=0;j<sizeof(buf)/2;j++) */
   /*   buf[j]=0xff; */
   /* for(int j=sizeof(buf)/2;j<sizeof(buf);j++) */
   /*   buf[j]=0x00; */
   
   /* buf[1] = 0; */
   
   for(int i=0;i<3;i++){
     for(int j=0;j<sizeof(buf);j++)
       buf[j]=255 ; //(255.*j/sizeof(buf));

     ftdi_write_data(ftdi,buf,sizeof(buf));
     usleep(32000);
   }
   

    printf("%d\n",ftdi->type);

    if ((ret = ftdi_usb_close(ftdi)) < 0)
    {
        fprintf(stderr, "unable to close ftdi device: %d (%s)\n", ret, ftdi_get_error_string(ftdi));
        ftdi_free(ftdi);
        return EXIT_FAILURE;
    }

    ftdi_free(ftdi);

    return EXIT_SUCCESS;
}
