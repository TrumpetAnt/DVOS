// This file is created in order to be used as documentation until a beter option is created.
// Please note that the inputs and outputs of the functions is still likely to change drastically, and that this is created as a templett to work from.
// pcb <=> process controll block.
// The functions in this module should only be accessible by the operating system and not the user directly.
// All functions should be thread safe.

/*
 * Initiate the memory manager
 */
void init();

/*
 * Call when a memory error happened
 * Examples of memory errors:
 * A process tried to access protected memory
 * A process tried to write to a read only variable
 * A process tried to read or write to memory that currently is on disk
 * @return A message to the operating system about what to do with this process
 * Please not that the return value is not actually returned but rather passed to another routine in the operating system
 */
msg memsig();

/*
 * Allocate operating system memory
 * @param size The normalized size of the memory to allocate
 * @return A pointer to the allocated memory
 */
void* sysalloc(size_t size);

/*
 * Free operating system memory
 * @param ptr Pointer to the memory to free
 */
void sysfree(void* ptr);

/*
 * Allocate the memory for a new process
 * @param text Text size
 * @param rodata Read only data size
 * @param rwdata Read-Write data size
 * @param bbs "Uninitialized data segment" size
 * @param heap Start heap size
 * @param stack Start stack size
 * @return The pointer to the new process's pcb (that also was created and hade the memory segment initiated in this function)
 */
void* psalloc(size_t text, size_t rodata, size_t rwdata, size_t bbs, size_t heap, size_t stack);

/*
 * Free the memory needed for a process
 * @param pcb Pointer to the pcb of the process to free
 */
void psfree(void* pcb);

/*
 * Allocate the memory for a new thread, including updating the memory segment in the pcb
 * @param pcb Pointer to the pcb of the process that this thread should belong to
 */
void tdalloc(void* pcb);

/*
 * Free the memory needed for a thread
 * @param pcb Pointer to the pcb of the process that the thread belongs to
 * @param tid Thread id
 */
void tdfree(void* pcb, size_t tid);

/*
 * TODO update to somthing better
 * Increase the/create more/map in more memory of a process
 * @param pcb Pointer to the pcb of the process
 */
void psmalloc(void* pcb);

/*
 * TODO update to somthing better
 * Opposite of psmalloc
 * @param pcb Pointer to the pcb of the process
 */
void psmfree(void* pcb);
