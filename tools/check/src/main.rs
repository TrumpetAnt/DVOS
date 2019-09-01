use std::fs::*;

fn main() {
    test_file_structure();
    let list = find_all_rust_projects();
    for project in list.into_iter() {
        let (name, file) = find_all_rust_files(project);
        for i in 0..name.len() {
            test_rust_file(name.pop(), file.pop());
        }
    }
}

fn test_rust_file(path: String, content: String) {
}

fn find_all_rust_files(project_name: String) -> (Vec<String>, Vec<String>) {
    let name:String = "../../rust/".to_owned() + &project_name + "/src";
    let mut names = Vec::new();
    let mut files = Vec::new();
    for entry in read_dir(&name).unwrap() {
        let entry = entry.unwrap();
        let path = name.clone() + entry.file_name().to_str().unwrap();
        files.push(read_to_string(&path).unwrap());
        names.push(path);
    }
    (names, files)
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
        for i in 0..all_files.len() {
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
