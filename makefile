# export PATH=$PATH:/media/sda5/altera/13.0sp1/quartus/linux64
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/media/sda5/altera/13.0sp1/quartus/linux64

all:
	quartus_map test.bdf
	quartus_fit test.bdf
	quartus_asm test.bdf
	upload_morphic output_file/test.rbf 
