// This file is created in order to be used as documentation until a beter option is created.
// Please note that the inputs and outputs of the functions is still likely to change drastically, and that this is created as a templett to work from.
// The functions in this module should only be accessible by the operating system and not the user directly.
// All functions should be thread safe.

/*
 * Initiate the disk manager
 */
void init();

/*
 * Blocking read from disk
 * @param ???
 * TODO: delete this function?
 */
void bread();

/*
 * Blocking write to disk
 * @param ???
 * TODO: delete this function?
 */
void bwrite();

/*
 * Non blocking read from disk
 * @param ???
 */
void read();

/*
 * Non blocking write to disk
 * @param ???
 */
void write();

/*
 * A non blocking call has completed its task
 * @return A message to the operating system
 * Please not that the return value is not actually returned but rather passed to another routine in the operating system
 */
msg done();
