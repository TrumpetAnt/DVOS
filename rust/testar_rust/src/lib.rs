#![crate_type = "staticlib"]
#![no_std]
#![no_main]

use core::panic::PanicInfo;
//pub mod a_mod;
// ld
// ar

extern "C" {
    pub fn test_hej(in1: usize) -> usize;
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
	loop{}
}

#[no_mangle]
pub unsafe extern "C" fn hej_hej(in1: usize) -> usize {
	test_hej(in1+1) + (*(0xffff as *const usize))
}

/*#[no_mangle]
pub extern "C" fn _start() -> ! {
	unsafe{hej_hej(5);}
	hej_hej_2(0);
	hej_3(2);
hej_4(1);
	//unsafe{test_hej(3);}
	loop{}
}*/

#[no_mangle]
pub unsafe extern "C" fn hej_hej_2(in1: usize) -> usize {
	in1.wrapping_add(3) + hej_hej(in1)
}

/*#[no_mangle]
pub extern "C" fn hej_3(in1: usize) -> usize {
	unsafe{test_hej(in1) + 1}
}


pub fn hej4(in1: usize) -> usize {
    unsafe{test_hej(5)}
}
*/
