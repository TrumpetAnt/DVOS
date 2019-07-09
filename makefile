
build_peter:
	@find -name *.asm | xargs -rtn1 fasm
	@xxd -ps ./src/bootloader/bootloader.bin > dvos.temp
	@xxd -ps ./src/kernel/kernel.bin >> dvos.temp
#	@xxd -ps ./src/zero.bin >> dvos.temp
	@xxd -r -p dvos.temp > dvos.img
	@rm dvos.temp
	@find -name *.bin | xargs -r rm
#	mv dvos.img ../../bochs/bochs-2.6.9/dvos.img
