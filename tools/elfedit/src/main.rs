use std::fs::*;
use byteorder::{ByteOrder, LittleEndian};
use std::str::from_utf8;

fn bread(buff: &[u8], size: usize) -> usize {
    assert!(buff.len() == size);
    assert!(size < 9 && size > 0);
    LittleEndian::read_uint(buff, size) as usize
}

fn print_txt(buff: &[u8]) -> &str {
    let mut i = 0;
    while buff[i] != 0 {
        i += 1;
    }
    from_utf8(&buff[0..i]).unwrap()
}

fn main() {
    print_elf();
}

fn print_elf() {
    let elf = read("a.o3").unwrap();
    
    println!("elf header:");
    
    print!("  elf magic number: ");
    assert!(elf[0x0..0x4] == [0x7f, 0x45, 0x4c, 0x46]);
    print!("{:X} ", elf[0]);
    for i in 0x1..0x4 {
        print!("{}", (elf[i] as char));
    }
    println!("");

    assert!(elf[0x4] == 2);
    println!("  64-bit elf file");

    assert!(elf[0x5] == 1);
    println!("  little endian elf file");

    assert!(elf[0x6] == 1);
    println!("  elf version: {:X}", elf[0x6]);

    println!("  target os abi is {:X} and {:X}", elf[0x7], elf[0x8]);

    println!("  object file type: {:X}", bread(&elf[0x10..0x12], 2));

    assert!(bread(&elf[0x12..0x14], 2) == 0x3e);
    println!("  x86-64 machine");

    assert!(bread(&elf[0x14..0x18], 4) == 1);
    println!("  elf version (again): {:X}", bread(&elf[0x14..0x18], 4));

    println!("  virtual memory start address: {:X}", bread(&elf[0x18..0x20], 8));

    let pht_start = bread(&elf[0x20..0x28], 8);
    println!("  program header start at: {:X}", pht_start);

    let sht_start = bread(&elf[0x28..0x30], 8);
    println!("  section header start at: {:X}", sht_start);

    println!("  special flags: {:X}", bread(&elf[0x30..0x34], 4));

    assert!(bread(&elf[0x34..0x36], 2) == 0x40);
    println!("  elf header size: {:X}", bread(&elf[0x34..0x36], 2));

    println!("  program header entry size: {:X}", bread(&elf[0x36..0x38], 2));

    let pht_size = bread(&elf[0x38..0x3a], 2);
    assert!((bread(&elf[0x36..0x38], 2) == 0x38) ^ (pht_size == 0));
    println!("  number of program header entrys: {:X}", pht_size);

    assert!(bread(&elf[0x3a..0x3c], 2) == 0x40);
    println!("  section header entry size: {:X}", bread(&elf[0x3a..0x3c], 2));

    let sht_size = bread(&elf[0x3c..0x3e], 2);
    assert!(sht_size > 0);
    println!("  number of section header entrys: {:X}", sht_size);

    let i_sht_names = bread(&elf[0x3e..0x40], 2);
    println!("  index to the section names: {:X}", i_sht_names);

    let sht_names_start = bread(&elf[(sht_start+i_sht_names*0x40+0x18)..(sht_start+i_sht_names*0x40+0x20)], 8);

    let mut sst_start:Option<usize> = None;
    for i in 0..sht_size {
        let start = sht_start + i*0x40;
        let section_type = bread(&elf[(start+0x4)..(start+0x8)], 4);
        if section_type == 2 {
            let section_start = bread(&elf[(start+0x18)..(start+0x20)], 8);
            sst_start = Some(section_start);
            break;
        }
    }
    let sst_start:usize = sst_start.unwrap();

    if pht_size == 0 {
        println!("\nno program headers");
    } else {
        for i in 0..pht_size {
            println!("\nprogram header {:X}:", i);
            let start = pht_start + i*0x38;

            println!("  segment type: {:X} ({})", bread(&elf[start..(start+0x4)], 4), match bread(&elf[start..(start+0x4)], 4) {0 => "NULL, 1", 1 => "LOAD", 2 => "DYNAMIC", 3 => "INTERP", 4 => "NOTE", 5 => "SHLIB", 6 => "PHDR", _ => "PROGRAM SPECIFIC",});

            let flags = bread(&elf[(start+0x4)..(start+0x8)], 4);
            assert!(flags < 8);
            println!("  flags: {:X} ({}{}{})", flags, if flags & 1 == 1 {'E'} else {' '}, if flags & 2 == 2 {'W'} else {' '}, if flags & 4 == 4 {'R'} else {' '});

            println!("  segment position: {:X}", bread(&elf[(start+0x8)..(start+0x10)], 8));

            println!("  virtual memory address: {:X}", bread(&elf[(start+0x10)..(start+0x18)], 8));

            println!("  physical memory address: {:X}", bread(&elf[(start+0x18)..(start+0x20)], 8));

            println!("  size of segment: {:X}", bread(&elf[(start+0x20)..(start+0x28)], 8));

            println!("  memory size of segment: {:X}", bread(&elf[(start+0x28)..(start+0x30)], 8));

            println!("  alignment: {:X}", bread(&elf[(start+0x30)..(start+0x38)], 8));
        }
    }

    for i in 0..sht_size {
        println!("\nsection header {:X}:", i);
        let start = sht_start + i*0x40;

        println!("  section name: {}", print_txt(&elf[sht_names_start+bread(&elf[start..(start+0x4)], 4)..]));

        let section_type = bread(&elf[(start+0x4)..(start+0x8)], 4);
        println!("  section type: {:X} ({})", section_type, match section_type {0 => "NULL", 1 => "PROGBITS", 2 => "SYMTAB", 3 => "STRTAB", 4 => "RELA", 5 => "HASH", 6 => "DYNAMIC", 7 => "NOTE", 8 => "NOBITS", 9 => "REL", 0xa => "SHLIB", 0xb => "DYNSYM", 0xe => "INIT_ARRAY", 0xf => "FINI_ARRAY", 0x10 => "PREINIT_ARRAY", 0x11 => "GROUP", 0x12 => "SYMTAB_SHNDX", 0x13 => "NUM", _ => "PROGRAM SPECIFIC",});

        let flags = bread(&elf[(start+0x8)..(start+0x10)], 8);
        if flags < 0x800 {
            println!("  section flags: {:X} ({}{}{}{}{}{}{}{}{}{}{})", flags, if flags & 1 == 1 {'W'} else {' '}, if flags & 2 == 2 {'A'} else {' '}, if flags & 4 == 4 {'E'} else {' '}, if flags & 8 == 8 {'U'} else {' '}, if flags & 0x10 == 0x10 {'M'} else {' '}, if flags & 0x20 == 0x20 {'S'} else {' '}, if flags & 0x40 == 0x40 {'I'} else {' '}, if flags & 0x80 == 0x80 {'L'} else {' '}, if flags & 0x100 == 0x100 {'O'} else {' '}, if flags & 0x200 == 0x200 {'G'} else {' '}, if flags & 0x400 == 0x400 {'T'} else {' '});
        } else {
            println!("  section flags: {:X} ({})", flags, "PROGRAM SPECIFIC FLAGS");
        }

        println!("  virtual memory address: {:X}", bread(&elf[(start+0x10)..(start+0x18)], 8));

        let section_start = bread(&elf[(start+0x18)..(start+0x20)], 8);
        println!("  section position: {:X}", section_start);

        let section_size = bread(&elf[(start+0x20)..(start+0x28)], 8);
        println!("  section size: {:X}", section_size);

        println!("  section link: {:X}", bread(&elf[(start+0x28)..(start+0x2c)], 4));

        println!("  section info: {:X}", bread(&elf[(start+0x2c)..(start+0x30)], 4));

        println!("  alignment: {:X}", bread(&elf[(start+0x30)..(start+0x38)], 8));

        let entry_size = bread(&elf[(start+0x38)..(start+0x40)], 8);
        println!("  entry size: {:X}", entry_size);

        if entry_size != 0 {
            assert!(section_size % entry_size == 0);
            let num = (section_size / entry_size) as usize;
            match section_type {
                2 => {
                    assert!(entry_size == 0x18);
                    for j in 0..num {
                        let star = section_start + j*0x18;
                        println!("\n  section symbol table entry {}:", j);

                        println!("    entry name: {}", print_txt(&elf[sht_names_start+bread(&elf[star..(star+0x4)], 4)..]));

                        assert!(elf[star+0x4] & 0xf < 7);
                        assert!(elf[star+0x4] >> 4 < 3);
                        println!("    entry info: {:X} ({} {})", elf[star+0x4], match elf[star+0x4] & 0xf {0 => "NOTYPE", 1 => "OBJECT", 2 => "FUNC", 3 => "SECTION", 4 => "FILE", 5 => "COMMON", 6 => "TLS", _ => panic!()}, match elf[star+0x4] >> 4 {0 => "LOCAL", 1 => "GLOBAL", 2 => "WEAK", _ => panic!()});

                        assert!(elf[star+0x5] < 4);
                        println!("    entry other (visibility): {:X} ({})", elf[star+0x5], match elf[star+0x5] {0 => "DEFAULT", 1 => "INTERNAL", 2 => "HIDDEN", 3 => "PROTECTED", _ => panic!()});

                        let ndx = bread(&elf[(star+0x6)..(star+0x8)], 2);
                        match ndx {
                            0x0000 => println!("    entry ndx: UND"),
                            0xFFF1 => println!("    entry ndx: ABS"),
                            _ =>      println!("    entry ndx: {:X}", ndx),
                        }

                        println!("    entry value: {:X}", bread(&elf[(star+0x8)..(star+0x10)], 8));

                        println!("    entry size: {:X}", bread(&elf[(star+0x10)..(star+0x18)], 8));
                    }
                },
                4 => {
                    assert!(entry_size == 0x18);
                    for j in 0..num {
                        let star = section_start + j*0x18;
                        println!("\n  section relocation table entry {}:", j);

                        println!("    offset: {:X}", bread(&elf[star..(star+0x8)], 8));

                        let info = bread(&elf[(star+0x8)..(star+0x10)], 8);
                        let info_sym = info >> 32;
                        let info_type = info & 0xffffffff;
                        println!("    info: {:X} (sym:{:X} (name:{}), type:{:X} ({}))", info, info_sym, print_txt(&elf[sht_names_start+bread(&elf[(sst_start+info_sym*0x18)..(sst_start+info_sym*0x18+0x4)], 4)..]), info_type, match info_type {9 => "x86-64 GOTPCREL", _ => "TODO add in more types"});

                        let addend :isize = (bread(&elf[(star+0x10)..(star+0x18)], 8)) as isize;
                        if addend < 0 {
                            println!("    addend: -{:X}", (0-addend));
                        } else {
                            println!("    addend: {:X}", addend);
                        }
                    }
                },
                9 => {
                    assert!(entry_size == 0x10);
                    for j in 0..num {
                        let star = section_start + j*0x10;
                        println!("\n  section relocation table entry {}:", j);

                        println!("    offset: {:X}", bread(&elf[star..(star+0x8)], 8));
                        
                        println!("    info: {:X} (TODO explain)", bread(&elf[(star+0x8)..(star+0x10)], 8));
                    }
                },
                _ => {println!("    TODO: print section entrys here");},
            }
        } else if section_size != 0 {
            print!("\n  secion content:");
            for j in 0..section_size {
                let byte = elf[section_start + j];
                if byte < 0x10 {
                    print!(" 0{:X}", byte);
                } else {
                    print!(" {:X}", byte);
                }
            }
            println!("");
        }
    }
}
