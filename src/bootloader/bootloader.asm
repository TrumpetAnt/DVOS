	use16
	ORG 0x7c00

	;; disable interrupts
	cli

	;; initialize segment registers
	xor ax, ax
	mov ss, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	;; set stack pointer
	mov sp, 0x7000
	mov bp, sp
	;; set stream pointer
	mov si, sp
	mov di, sp
	
	;; canonicalize segment:offset
	jmp  0:next_line_of_code
	next_line_of_code:
	
	;; enable interrupts
	sti
	
	;; clear direction flag, "string" operations will count towards bigger memory addresses
	cld
	
	;; input arguments to int 13h
	mov bx, $7e00
	xor dh, dh
	mov ah, $2
	mov al, $1
	xor ch, ch
	mov cl, $2
	;; read sectors from drive
	int 13h

	;; if int 13h fails, try again, else done
	jnc load_hard_drive_done
	
	;; loop has been unrolled
	mov ah, $0
	int 10h

	mov ah, $2
	int 13h

	jnc load_hard_drive_done

	mov ah, $0
	int 10h

	mov ah, $2
	int 13h

	jnc load_hard_drive_done

	;; print error
print_error_and_halt:	
	mov si, bootloader_error_text
print_and_halt:	
	mov ah, $e
	mov bh, $0
	mov ch, $0
print_loop:
	lodsb
	mov cl, al
	jcxz halt
	int 10h
	jmp print_loop
halt:
	hlt
	jmp halt
	
load_hard_drive_done:
	;; test if 0x534f5644 (DVOS) exist
	cmp word[0x7e00], 0x5644
	jne print_error_and_halt
	cmp word[0x7e02], 0x534f
	jne print_error_and_halt
	
	;; test if long mode exist (64-bit protected mode is called long mode)
	xor ax, ax
	add ax, ax
	pushf
	pop ax
	test ax, $2
	jz bit_16_error
	
	pushfd
	pop eax
	xor eax, 0x200000
	mov ebx, eax
	push eax
	popfd
	pushfd
	pop eax
	mov ecx, ebx
	xor ecx, 0x200000
	push ecx
	popfd
	test eax, ebx
	jz bit_32_error

	mov eax, 0x80000000
	cpuid
	cmp eax, 0x80000001
	jb bit_32_error

	mov eax, 0x80000001
	cpuid
	test edx, 0x20000000
	jz bit_32_error
	
	;; long mode exist :), continue execution

	;; enable A20
	mov ax, 2401h
	int 15h

	;; clear the memory from 0x7000 to 0x7c00
	xor eax, eax
	mov ecx, 0x300
	rep stosd
	mov di, si

	std
	mov ebx, 0x0
	mov cx, 0xc0
smap_loop_dec:
	mov [smap_array_size], cl
smap_loop:
	mov eax, 0x0000E820
	mov ecx, 0x14
	mov edx, 0x534D4150
	int 15h

	jc smap_loop_end
	cmp ebx, $0
	jz smap_loop_end
	
	mov cx, 0xc0
	sub cl, [smap_array_size]
	jcxz smap_outer_loop_end
	push si
	mov si, di
	sub si, 0xc
smap_iner_loop:
	lodsd
	mov edx, eax
	lodsd
	;; eax = BaseAddrLow, edx = BaseAddrHigh

	cmp edx, [di+4]
	jb smap_has_find_pos
	cmp eax, [di]
	jbe smap_has_find_pos
	sub si, 0x8
	loop smap_iner_loop
smap_has_find_pos:
	pop si
	push bx
	mov bx, cx
	shl bx, $4
	add eax, [si+bx+8]
	adc edx, [si+bx+12]
	pop bx
	
	cmp edx, [di+4]
	jb smap_move_array
	cmp eax, [di]
	jb smap_move_array

	;; overlaping data
	;; [insert code here]
	jmp smap_outer_loop_end
	
smap_move_array:
	;; [insert code here]
smap_outer_loop_end:
	add di, 0x10
	xor cx, cx
	mov cl, [smap_array_size]
	loop smap_loop_dec

	;; smap array overflow!
	;; [insert code here]

smap_loop_end:
	;; end of smap loop
	;; [insert code here]
	
	;; temp code
	mov si, done
	jmp print_and_halt
	
	
bit_16_error:
	mov si, bit_16_error_text
	jmp print_and_halt

bit_32_error:
	mov si, bit_32_error_text
	jmp print_and_halt

	
done db 'this code has done its job', $0
bootloader_error_text db 'could not find the kernel', $0
bit_16_error_text db 'somehow you manage to boot this on a 16-bit machine', $0
bit_32_error_text db 'DVOS only suport 64-bit machines and this is a 32-bit machine', $0
bootloader_unknown_error_text db 'a unknown error has happend :(', $0
smap_array_size db $0
	
;; puting 0xaa55 at the end of the file to make sure that the BIOS can find/load this
;==================================
; times $1FE-($-$$) db 0
db 0x55
db 0xAA
;==================================
db 'DVOS'
;==================================
	
	
	
	
	
	
;==================================
times $400-($-$$) db 0
;==================================
