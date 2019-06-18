	use64
	ORG 0xD000
start:
	;; kernel start position from the bootloader
	;; you are in 32-bit submode of 64-bit long mode


	


;; end of file, add 0x200 to the number if assembler is complaining, and add 1 to the number in the bootloader on line xx.
;==================================
times 0x200-($-$$) db 0
;==================================
	
