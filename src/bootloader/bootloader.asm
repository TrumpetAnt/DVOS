	ORG 0x7c00
	
	;; input arguments to int 13h
	xor ax, ax
	mov es, ax
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
	cld
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
	
	;; done
	;; [insert code here]
	
	;; temp code
	mov si, done
	jmp print_and_halt

load_kernel:
	;; disable interrupts
	cli

	;; initialize segment registers
	mov ax, 0
	mov ss, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	;; set stack pointer
	mov sp, 0x6000
	
	;; canonicalize segment:offset
	;; ljmp  $0, $next_line_of_code
	;;  next_line_of_code:
	
	;; enable interrupts
	sti

	;FASM
use16
mov     ax,2403h                ;--- A20-Gate Support ---
int     15h
jb      a20_ns                  ;INT 15h is not supported
cmp     ah,0
jnz     a20_ns                  ;INT 15h is not supported
 
mov     ax,2402h                ;--- A20-Gate Status ---
int     15h
jb      a20_failed              ;couldn't get status
cmp     ah,0
jnz     a20_failed              ;couldn't get status
 
cmp     al,1
jz      a20_activated           ;A20 is already activated
 
mov     ax,2401h                ;--- A20-Gate Activate ---
int     15h
jb      a20_failed              ;couldn't activate the gate
cmp     ah,0
jnz     a20_failed              ;couldn't activate the gate
 
a20_failed:
	jmp print_and_halt
	
a20_ns:
	jmp print_and_halt

a20_activated:                  ;go on
	
done db 'this code has done its job', $0
err_2 db 'extra: '	
bootloader_error_text db 'could not find the kernel', $0
	;; puting 0xaa55 at the end of the file to make sure that the BIOS can find/load this
;==================================
times $1FE-($-$$) db 0
db 0x55
db 0xAA
;==================================
db 'DVOS'
;==================================
	
	
	
	
	
	
;==================================
times $400-($-$$) db 0
;==================================
