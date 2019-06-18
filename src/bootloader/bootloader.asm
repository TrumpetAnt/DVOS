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
	cli
hlt_l:
	hlt
	jmp hlt_l
	
load_hard_drive_done:
	;; test if 0x534f5644 (DVOS) exist
	cmp [0x7e00], word 0x5644
	jne print_error_and_halt
	cmp [0x7e02], word 0x534f
	jne print_error_and_halt

	;; load in extra data at 0x5000
	mov bx, 0x5000
	mov cl, $3
	int 13h
	
	;; test if long mode exist (64-bit protected mode is called long mode)
	xor ax, ax
	add ax, ax
	pushf
	pop ax
	test ax, $2
	jz bit_16_error

	;; disable interrupts
	cli

	;; set stack pointer
	mov esp, 0x7000
	mov ebp, esp
	;; set stream pointer
	mov esi, esp
	mov edi, esp
	
	;; enable interrupts
	sti
	
	;; continue testing if long mode exist
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

	;; get the memory map and put it in 0x7000 to 0x7c00
	std
	xor ebx, ebx
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

	cmp dword [di+16], $1
	jz smap_continue
	
smap_loop_zero:
	xor eax, eax
	mov [di], eax
	mov [di+4], eax
	mov [di+8], eax
	mov [di+12], eax
	mov [di+16], eax
	
	jmp smap_loop

bootloader_error_text db 'could not find the kernel', $0
bit_16_error_text db 'somehow you manage to boot this on a 16-bit machine, only 64-bit is suported :(', $0
bit_32_error_text db 'DVOS only suport 64-bit machines and this is a 32-bit machine', $0
smap_array_size db $0
bootloader_crash db 'bootloader has crashed :(', $0
	
;; puting 0xaa55 at the end of the file to make sure that the BIOS can find/load this
;==================================
times 0x1FE-($-$$) db 0
db 0x55
db 0xAA
;==================================
	
db 'DVOS'
	
;==================================
	
smap_continue:
	mov [di+16], dword $0
	mov cx, 0xc0
	sub cl, [smap_array_size]
	jcxz smap_outer_loop_end_temp
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
	jmp smap_has_find_pos

smap_outer_loop_end_temp:
	jmp smap_outer_loop_end
	
smap_has_find_pos:
	pop si
	push bx
	mov bx, 0xc0
	sub bl, [smap_array_size]
	sub bx, cx
	shl bx, $4
	add eax, [si+bx+8]
	adc edx, [si+bx+12]
	pop bx
	
	cmp edx, [di+4]
	jb smap_move_array
	cmp eax, [di]
	jb smap_move_array

	;; overlaping data
	push eax
	push edx
	mov eax, [di+8]
	mov edx, [di+12]
	add [di], eax
	adc [di+4], edx
	pop edx
	pop eax

	cmp edx, [di+4]
	ja smap_loop_zero
	cmp eax, [di]
	jae smap_loop_zero

	sub [di], eax
	sbb [di+4], edx
	mov eax, [di]
	mov edx, [di+4]

	push bx
	mov bx, 0xc0
	sub bl, [smap_array_size]
	sub bx, cx
	shl bx, $4
	add [si+bx+8], eax
	adc [si+bx+12], edx
	pop bx
	
	jmp smap_loop_zero
	
smap_move_array:
	push si
	push di
	mov eax, [di]
	push eax
	mov eax, [di+4]
	push eax
	mov eax, [di+8]
	push eax
	mov eax, [di+12]
	push eax

	add di, 0xc
	mov si, di
	sub si, 0x10

	mov eax, ecx
	mov ecx, 0xc0
	sub cl, [smap_array_size]
	sub ecx, eax
	shl ecx, $2
	
	rep movsd

	add di, $4
	pop eax
	mov [di+12], eax
	pop eax
	mov [di+8], eax
	pop eax
	mov [di+4], eax
	pop eax
	mov [di], eax
	pop di
	pop si
smap_outer_loop_end:
	add di, 0x10
	xor cx, cx
	mov cl, [smap_array_size]
	loop smap_loop_dec_temp

	;; smap array overflow!
	mov si, bootloader_crash
	cld
	jmp print_and_halt

smap_loop_dec_temp:
	jmp smap_loop_dec

smap_loop_end:
	cld
	cmp [di+16], dword $1
	jnz smap_end

	;; TODO
	;; [insert code here]
	;; temp code
	mov si, bootloader_crash
	jmp print_and_halt
	
smap_end:
	;; end of "get memory map" (memory map is now in 0x7000 to 0x7c00, and the number of elements in this array is 0xc0-[smap_array_size])

	;; clear the page table memory
	mov edi, 0x1000
	mov esi, edi
	mov ecx, edi
	xor eax, eax
	rep stosd

	;; inserting entrys
	mov [si], word 0x2007		; setting up PML4T
	mov [si+0x1000], word 0x3007	; setting up PDPT
	mov [si+0x2000], word 0x4007	; setting up PDT
	;; setting up PT
	add si, 0x3000
	mov di, si
	or al, 0x7
	mov ecx, 0x200
page_table_loop:
	stosd
	add di, 0x4
	add eax, 0x1000
	loop page_table_loop

	;; disable interrupts
	cli
	
	;; Load a zero length IDT (Interrupt Descriptor Table) so that any NMI (Non-Maskable Interrupt) causes a triple fault.
	sidt [OIDT]
	lidt [IDT]

	;; set to 64-bit pages
	mov eax, 0xa0
	mov cr4, eax

	;; set pointer to PML4T
	mov eax, 0x1000
	mov cr3, eax

	mov ecx, 0xC0000080	; Set the C-register to 0xC0000080, which is the EFER MSR.
	rdmsr			; Read from the model-specific register.
	or eax, 0x100		; Set the LM(Long Mode)-bit which is the 9th bit (bit 8).
	wrmsr			; Write to the model-specific register.

	mov ebx, cr0		; Activate long mode -
	or ebx,0x80000001	; - by enabling paging and protection simultaneously.
	mov cr0, ebx

	lgdt [GDT.Pointer]	; Load GDT.Pointer defined below.

	;; jump to the kernel
	;jmp 0:0xD000
	jmp 0:halt_64
	
bit_16_error:
	mov si, bit_16_error_text
	jmp print_and_halt

bit_32_error:
	mov si, bit_32_error_text
	jmp print_and_halt
	
	use64
halt_64:
	hlt
	jmp halt_64
	use16
	
;==================================
times 0x400-($-$$) db 0
;==================================

	ORG 0x5000

ALIGN 4
OIDT:
OLength dw 0
OBase dd 0
ALIGN 4
IDT:
Length dw 0
Base dd 0
	
; Global Descriptor Table
GDT:
.Null:
    dq 0x0000000000000000             ; Null Descriptor - should be present.
 
.Code:
    dq 0x00209A0000000000             ; 64-bit code descriptor (exec/read).
    dq 0x0000920000000000             ; 64-bit data descriptor (read/write).
 
ALIGN 4
    dw 0                              ; Padding to make the "address of the GDT" field aligned on a 4-byte boundary
 
.Pointer:
    dw $ - GDT - 1                    ; 16-bit Size (Limit) of GDT.
    dd GDT                            ; 32-bit Base Address of GDT. (CPU will zero extend to 64-bit)
	
;==================================
times 0x200-($-$$) db 0
;==================================
