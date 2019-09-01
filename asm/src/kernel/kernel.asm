	use64
	ORG 0xD000
start:
	;; kernel start position from the bootloader

halt:
	hlt
	jmp halt
	


;; end of file, add 0x200 to the number if assembler is complaining, and add 1 to the number in the bootloader on line 377 (mov al, _).
;==================================
times 0x200-($-$$) db 0
;==================================
