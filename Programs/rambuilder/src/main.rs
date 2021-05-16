use std::env;
use std::fs;
use std::u8;


fn main() {
    let file = "D:/FPGA/PGB/Programs/rambuilder/tetris_vram.dump";

    let template = "D:/FPGA/PGB/Programs/rambuilder/blockram_template.vhd";

    let output = "D:/FPGA/PGB/Programs/rambuilder/tetris_vram.vhd";

    let data_contents = fs::read(file).expect("File not found");

    let template_code = fs::read_to_string(template).expect("File not found");

    let ramsize = data_contents.len();
    let ramname = "tetris_vram";

    let mut datavhdl = "".to_string();

    for b in data_contents {
        let mut byte = format!("{:#04x}\",",b);
      
        datavhdl.push_str(&byte.replace("0x","x\""));       
    }

    let strinlen = (datavhdl.len()-1);
    
    let newcode = template_code.replace("$ramname", ramname).replace("$ramsize", &format!("{}",ramsize)).replace("$ramdata",&datavhdl[0..strinlen]);

    fs::write(output,newcode);
   
}
