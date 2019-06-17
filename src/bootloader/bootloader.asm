	ORG 0x7c00
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
  mov bp, sp
  
  ;; canonicalize segment:offset
  ;; ljmp  $0, $next_line_of_code
  ;;  next_line_of_code:
  
  ;; enable interrupts
  sti

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
	
	;; loop has been unroled
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
