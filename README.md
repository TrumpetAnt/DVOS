# DVOS
Warning this is how it is going to look/work when all tools is in place, and currently this is not the case.
### Makefile
* `make build` builds the operating system and makes a *dvos.img* file.
* `make test` runs all rust unit tests.
* `make rust` creates a new rust project template with everything set to correctly compile when `make build` is runned.
* `make check` goes through all special commands and make sure they are correct as well as updating auto generated code.

### Special commands and layouts
No function, file or project name is allowed to have a '.' character in its name.
#### Export and Inport functions
All exported function (both asm and rust functions) has to have a unique name.<br />
All exported function and calls to external functions in asm has to follow the *System V AMD64 ABI* standard, and it's up to the programmer to make sure that it is followed.<br />
All .asm files should start with a list of `dq name` separated with newline characters where `name` is replaced with the name of the function that you want to export.<br />
All rust function in *lib.rs* that is declared as `pub extern "C" fn` and with the attribute `#[no_mangle]` is exported. Please note that currently you can't export "pure" rust functions for use in other rust projects, and this feature will maybe come in the future.<br />
To call a external function in asm you write `call ;func` where `func` is replaced with the function name that you want to call.<br />
To inport a external function in rust you write `extern "C" { func }` were `func` is replaced with the function name and signature, and then you can call it like any other unsafe rust function.
#### Memory location
The *memory* file is a ascii formatted file that is a list of `name pos` separated with new line characters where `name` is replaced with the name of the object and `pos` with where it should be placed in memory.<br />
`name` is either the name of a .asm file, the name of a rust project or the name of a rust function. Examples: `asm_file`, `rust_project`, `rust_project.rust_function`.<br />
`pos` is either a hex number that corresponds to where in memory it should be placed or 'xx' to indicate that to should be placed after the previous item in the list. Examples: `0xf0d0`, `xx`, `0xdeadbeaf`.
#### Struct synchronization
All exported/tracked structs has to have a unique name.<br />
By writing `//-e` before a struct declaration in rust, than that struct is being exported/tracked. This is only neaded on structs that is also being handled by asm code [or rust code in another project?].<br />
By writing `;-w name` in asm where `name` is the name of the struct than the builder is going to produce a warning if the struct is being changed. When the struct is being change the builder is going to change `;-w name` to `;-w name 1` and is going to continue to produce warnings until it is change back to either `;-w name` or `;-w name 0`.<br />
By writing `//-i name` in rust where `name` is the name of the struct than the builder is going to copy in that struct here. If a change is made in the exported struct it is going to be changed in this struct to, and changes to this struct is going to be ignored.
#### *data* file
The *data* file is where the builder is storing data and should not be modified (or read) by a human.

### File Structure
* *makefile*
* *README.md*
* *memory*
* *data*
* *asm/*
  * all .asm files in a ***unspecified*** file structure
* *rust/*
  * *[insert rust project name here]/*
    * *Cargo.toml*
    * *Cargo.lock*
    * *.cargo/*
      * *config*
    * *src/*
      * *lib.rs*
      * *[maybe insert more rust files here]*
    * *target/*
      * *release/*
        * *[insert auto generated files here]*
* *tools/*
  * *[insert all tools here, this is a TODO in this file (README.md), and not a "I can't know what should be here"]*
* *[insert other things here, I don't know if this is a TODO or if it should be like this in this file (README.md)]*
