#[no_mangle]
pub extern "C" fn mod_fn(in1: usize) -> usize {
	in1+7
}
