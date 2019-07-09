use std::fs::File;
use std::io::prelude::*;
use std::env;
use std::iter::Iterator;
use goblin::{Object};
use std::fs::OpenOptions;

fn main() {
    let args = env::args();
    if args.count() != 3 {
        println!("\n\n\n\n");
        println!("Incorrect number of commandline arguments. Expected exacly two arguments.");
        return;
    }
    let arg = env::args().nth(1).unwrap();
    if let Ok(file) = File::open(&arg) {

        
        // 1. Hitta alla executable block.
        // 2. Hitta vilket som ar forsta.
        // 3. Ladda in alla block i ny fil.

        let mut fd = file;
        let mut buffer = Vec::new();
        fd.read_to_end(&mut buffer).unwrap();
        match Object::parse(&buffer).unwrap() {
            Object::Elf(elf) => {
                let mut exe_sections = Vec::new();
                for section_header in elf.section_headers {
                    if section_header.is_executable() {
                        exe_sections.push(section_header);
                    }
                }
                if exe_sections.len() != 1 {
                    println!("Panic #1");
                    return;
                } else {
                    let sh = exe_sections.pop().unwrap();
                    println!("Executable section found at @[{}] with length @[{}]", sh.sh_offset, sh.sh_size);

                    let arg = env::args().nth(2).unwrap();

                    if let Ok(mut file) = OpenOptions::new().append(true).open(&arg) {
                        if let Err(e) = file.write(&buffer[sh.file_range()]) {
                            println!("\n\nExited with error:\n\n{}", e);
                        }
                        
                    } else {
                        println!("Couldn't find file at '{}'", &arg);
                    }
                    
                }
            },
            Object::PE(_pe) => {
                println!("Expected ELF format. Got PE.");
                //println!("pe: {:#?}", &pe);
            },
            Object::Mach(_mach) => {
                println!("Expected ELF format. Got Mach.");
                //println!("mach: {:#?}", &mach);
            },
            Object::Archive(_archive) => {
                println!("Expected ELF format. Got Archive.");
                //println!("archive: {:#?}", &archive);
            },
            Object::Unknown(magic) => { println!("unknown magic: {:#x}", magic) }
        }
        
    } else {
        println!("Could not find file '{}'", arg);
    }
}
