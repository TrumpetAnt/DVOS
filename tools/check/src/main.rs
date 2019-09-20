use std::fs::*;
use std::path::Path;

static mut PANIC:bool = false;

// (path, content)
fn main() {
    test_file_structure();
    let list = find_all_rust_projects();
    let mut all_r_files = Vec::new();
    for project in list.into_iter() {
        all_r_files.append(&mut find_all_rust_files(project));
    }
    let mut all_structs = Vec::new();
    let mut all_r_funcs = Vec::new();
    for i in 0..all_r_files.len() {
        all_r_funcs.append(&mut test_no_mangle_rust_file(&all_r_files[i].0, &all_r_files[i].1));
        all_structs.append(&mut export_rust_structs(&all_r_files[i].1));
    }
    all_r_funcs.sort_unstable_by(|a, b| (**a).cmp(*b));
    all_structs.sort_unstable_by(|a, b| (**a).cmp(*b));
    let (old_all_r_funcs, old_all_structs) = read_data();
    let structs_warning = find_warning(&all_r_funcs, &old_all_r_funcs);
    let r_funcs_warning = find_warning(&all_structs, &old_all_structs);
    let all_a_files = find_all_asm_files();
    let mut a_funcs_warning = Vec::new();
    let mut ao_warning = Vec::new();
    for (_path, content) in all_a_files.iter() {
        a_funcs_warning.append(&mut find_a_warning(content));
        ao_warning.append(&mut find_ao_func(content));
    }
    for i in 0..all_r_files.len() {
        test_for_ao_func(&all_r_files[i].1, &ao_warning);
        trigger_r_warning(&all_r_files[i], &a_funcs_warning);
        update_r_file(&all_r_files[i], &r_funcs_warning, &structs_warning);
    }
    for i in 0..all_a_files.len() {
        trigger_a_warning(&all_a_files[i], &r_funcs_warning, &structs_warning);
        update_a_file(&all_a_files[i], &r_funcs_warning, &structs_warning);
    }
    unsafe {
        if PANIC {
            panic!();
        }
    }
}

fn trigger_r_warning(file: &(String, String), warning: &Vec<&str>) {
    
}

fn find_a_warning(content: &str) -> Vec<&str> {
    let mut vec = Vec::new();
    for line in content.lines() {
        if line[..3] == *"dq " {
            let name_end = line[3..].find(' ').unwrap();
            if let Some(c) = line.get((name_end+2)..(name_end+3)) {
                if *c == *"1" {
                    vec.push(&line[3..name_end]);
                }
            }
        } else {
            break;
        }
    }
    vec
}

fn find_ao_func(content: &str) -> Vec<&str> {
    let mut vec = Vec::new();
    for line in content.lines() {
        if line[..3] == *"dq " {
            let name_end = line[3..].find(' ').unwrap();
            if line[(name_end+1)..(name_end+2)] == *"a" {
                vec.push(&line[3..name_end]);
            }
        } else {
            break;
        }
    }
    vec
}

fn test_for_ao_func(content: &str, func_vec: &Vec<&str>) {
}

// (path, content)
fn find_all_asm_files() -> Vec<(String, String)> {
    let mut vec = Vec::new();
    for entry in read_dir("../../asm").unwrap() {
        let entry = entry.unwrap();
        if entry.file_type().unwrap().is_dir() {
            vec.append(&mut find_all_asm_files_req(entry.path().as_path()));
        } else {
            let s = entry.path().to_str().unwrap().to_string();
            if s[(s.len()-4)..] == *".asm" {
                vec.push((s, read_to_string(entry.path()).unwrap()));
            }
        }
    }
    vec
}

fn find_all_asm_files_req(pos: &Path) -> Vec<(String, String)> {
    let mut vec = Vec::new();
    for entry in read_dir(pos).unwrap() {
        let entry = entry.unwrap();
        if entry.file_type().unwrap().is_dir() {
            vec.append(&mut find_all_asm_files_req(entry.path().as_path()));
        } else {
            let s = entry.path().to_str().unwrap().to_string();
            if s[(s.len()-4)..] == *".asm" {
                vec.push((s, read_to_string(entry.path()).unwrap()));
            }
        }
    }
    vec
}

fn find_warning<'a>(new: &Vec<&str>, old: &'a Vec<String>) -> Vec<&'a str> {
    let mut i = 0;
    let mut j = 0;
    let mut w = Vec::new();
    while i < new.len() && j < old.len() {
        if (*new[i]) == old[j][..] {
            i = i+1;
            j = j+1;
        } else {
            if new[i][..(new[i].find(|c| c == ' ' || c == '(' || c == '{').unwrap())] == old[j][..(old[j].find(|c| c == ' ' || c == '(' || c == '{').unwrap())] {
                i = i+1;
                j = j+1;
                w.push(&old[j][..(old[j].find(|c| c == ' ' || c == '(' || c == '{').unwrap())]);
            } else {
                if (*new[i]) < old[i][..] {
                    i = i+1;
                } else {
                    j = j+1;
                    w.push(&old[j][..(old[j].find(|c| c == ' ' || c == '(' || c == '{').unwrap())]);
                }
            }
        }
    }
    w
}

fn read_data() -> (Vec<String>, Vec<String>) {
    let mut all_func = Vec::new();
    let mut all_strc = Vec::new();
    let data = read_to_string("../../data").unwrap();
    let mut func = true;
    for line in data.lines() {
        if line == "" {
            func = false;
        } else {
            if func {
                all_func.push(line.to_string());//TODO
            } else {
                all_strc.push(line.to_string());//TODO
            }
        }
    }
    (all_func, all_strc)
}

fn export_rust_structs(content: &str) -> Vec<&str> {
    let mut all_structs = Vec::new();
    let i = 0;
    while let Some(i) = content[i..].find("//-e") {
        let j = content[i..].find('\n').unwrap()+1;
        let k = content[j..].find('\n').unwrap()+1;
        if content[j..].find("#[repr(C)]").unwrap() != 0 || content[k..].find("pub struct ").unwrap() != 0 {
            panic!("a struct export error");
        }
        let mut num = 1;
        let mut left = content[k..].find('{').unwrap();
        while num != 0 {
            let right = content[(left+1)..].find('}').unwrap();
            if let Some(new_left) = content[(left+1)..right].find('{') {
                left = new_left;
                num = num+1;
            } else {
                num = num-1;
                left = right;
            }
        }
        all_structs.push(&content[(k+11)..(left+1)]);
    }
    all_structs
}

fn test_no_mangle_rust_file<'a>(path: &str, content: &'a str) -> Vec<&'a str> {
    let mut all_func = Vec::new();
    let i = 0;
    while let Some(i) = content[i..].find("#[no_mangle]") {
        let j = content[i..].find('\n').unwrap()+1;
        if content[j..].find("pub unsafe extern \"C\" fn ").unwrap() != 0 {
            panic!("a no_mangle error in file {}", &path[6..]);
        }
        all_func.push(&content[(j+25)..(content[j..].find('{').unwrap())]);
    }
    all_func
}

// (path, content)
fn find_all_rust_files(project_name: String) -> Vec<(String, String)> {
    let name:String = "../../rust/".to_owned() + &project_name + "/src";
    let mut vec = Vec::new();
    for entry in read_dir(&name).unwrap() {
        let entry = entry.unwrap();
        let path = name.clone() + entry.file_name().to_str().unwrap();
        let content = read_to_string(&path).unwrap();
        vec.push((path, content));
    }
    vec
}

fn find_all_rust_projects() -> Vec<String> {
    let mut vec = Vec::new();
    for entry in read_dir("../../rust").unwrap() {
        let entry = entry.unwrap();
        if !entry.file_type().unwrap().is_dir() {
            panic!("fond not a dir in rust dir");
        }
        vec.push(entry.file_name().to_str().unwrap().to_string());
    }
    vec
}

fn test_file_structure() {
    let mut find_all:[_; 7] = [false, false, false, false, false, false, false];
    let all_files:[_; 7] = ["memory", "data", "rust", "tools", "asm", "README.md", "makefile"];
    for entry in read_dir("../..").unwrap() {
        let entry = entry.unwrap();
        for i in 0..(all_files.len()) {
            if entry.file_name().to_str().unwrap() == all_files[i] {
                find_all[i] = true;
                break;
            }
        }
    }
    let mut all = true;
    for find in find_all.iter() {
        all = all && *find;
    }
    if !all {
        panic!("wrong file structure");
    }
}
