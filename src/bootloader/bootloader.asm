	ORG 0x7c00
load_kernel:
	;; input arguments to int 13h
	mov ax, $0
	mov es, ax
	mov bx, $7e00
	mov dh, $0
	mov dl, [drive]
	mov ah, $2
	mov al, $1
	mov ch, $0
	mov cl, $2
	;; read sectors from drive
	int 13h

	;; if int 13h fails, try again
	jc try_again

	;; test if 0x44564f53 (DVOS) exist
	cmp word[0x7e00], 0x4F53
	jne try_again_2
	cmp word[0x7e02], 0x4456
	jne try_again_2
	;; done
	;; [insert code here]

	;; try the same drive 5 times
try_again:
	inc byte[try]
	cmp byte[try], $5
	jne load_kernel
	
	;; try with a new drive
try_again_2:
	;; reset number of tries
	mov [try], $0

	;; change to a new drive
	cmp byte[drive], $0
	je drive_b
	cmp byte[drive], $1
	je drive_c
	cmp byte[drive], 0x80
	je drive_d
	cmp byte[drive], 0x81
	je drive_e
	
	;; error os not found
	;; [insert code here]

	;; change drive to test to B:
drive_b:
	mov [drive], $1
	jmp load_kernel

	;; change drive to test to C:
drive_c:
	mov [drive], 0x80
	jmp load_kernel

	;; change drive to test to D:
drive_d:
	mov [drive], 0x81
	jmp load_kernel

	;; change drive to test to E:
drive_e:
	mov [drive], 0xe0
	jmp load_kernel
	
	;; start with testing drive A:
	drive db 0

	;; number of tries
	try db 0

	
	;; puting 0xaa55 at the end of the file to make sure that the BIOS can find/load this
;==================================
times $1FE-($-$$) db 0
db 0x55
db 0xAA
;==================================
