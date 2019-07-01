
build_peter:
	@find -name *.asm | xargs -rtn1 fasm
	@find -name *.bin | xargs -rn1 xxd -ps | xxd -r -p > dvos.img
	@find -name *.bin | xargs -r rm -v
#	mv dvos.img ../../bochs/bochs-2.6.9/dvos.img
