	use64
	ORG 0x00D000

	;; disable cache on all blocks in the memory manager data section
	or qword [0x4040], 0x10
	;; or qword [0x4048], 0x10

	;; reload the page table
	mov rax, cr3
	mov cr3, rax

	;; test the memory system
	mov rbx, 0x7000
	
	mov rax, [rbx]
	cmp rax, 0x0
	jnz halt_and_catch_fire

	xor rcx, rcx
	mov cl, 0xc0
	sub cl, [0x7e04]

	mov rax, [rbx+8]
	cmp rax, 0x90000
	jb halt_and_catch_fire
	
memory_test_loop:
	cmp rax, 0x300000
	jae memory_fire_test_1_done

	dec cl
	jcxz halt_and_catch_fire

	add rbx, 0x10
	mov rax, [rbx]
	add rax, [rbx+8]
	jmp memory_test_loop

halt_and_catch_fire:
	;; do something
	hlt
	jmp halt_and_catch_fire
	
memory_fire_test_1_done:
	mov rax, [rbx]
	cmp rax, 0x100000
	ja halt_and_catch_fire
