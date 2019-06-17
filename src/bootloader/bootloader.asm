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

	;; cleare the memory from 0x7000 to 0x7c00
	xor eax, eax
	mov ecx, 0x300
	rep stosd
	mov di, si

	;; [insert code here]
	
	;; get system memory map
	mov ebx, 0x0
smap_loop:	
	mov eax, 0x0000E820
	mov ecx, 0x14
	mov edx, 0x534D4150
	int 15h

	;; test if the last segment
	jc smap_end
	mov ecx, ebx
	jcxz smap_end

	;; test if we should save the segment
	mov eax, [di+16]
	cmp eax, 1
	jnz smap_loop

	;; saves ebx in edx
	mov edx, ebx
	
	;; test against the last segment in the list
	mov bx, [si+2]
	mov ecx, [bx+4]		; BaseAddrHigh of last segment
	mov eax, [bx]		; BaseAddrLow of last segment

	cmp ecx, [di+4]
	ja sort_list
	jb list_is_maybe_sorted
	cmp eax, [di]
	ja sort_list
	jb list_is_maybe_sorted

	;; [insert code here]

list_is_maybe_sorted:
	add eax, [bx+8]
	adc ecx, [bx+12]
	
	cmp ecx, [di+4]
	ja list_is_sorted
	jb overlapping_areas_1
	cmp eax, [di]
	ja list_is_sorted
overlapping_areas_1:
	;; [insert code here]
	jmp smap_loop

list_is_sorted:
	mov bx, [si+2]
	mov word[bx+16], di
	mov word[si+2], di
	add di, 18
	jmp smap_loop
	
sort_list:	
	mov bx, [si]
	mov bx, [bx]
	jmp smap_list_loop_start
smap_list_loop:
	mov bx, [bx+16]
smap_list_loop_start:
	mov ecx, [bx+4]		; BaseAddrHigh of (first)/next segment
	mov eax, [bx]		; BaseAddrLow of (first)/next segment
	add eax, [bx+8]		; EndAddrLow of (first)/next segment
	adc ecx, [bx+12]	; EndAddrHigh of (first)/next segment
	
	cmp ecx, [di+4]
	jb smap_list_loop
	cmp eax, [bx]
	jmp smap_list_loop
	;; [insert code here]
	jmp smap_loop
	
smap_end:
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
