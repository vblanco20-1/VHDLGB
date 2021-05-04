use std::env;
use std::fs;
use std::collections::HashMap;
use std::u8;

struct VariableDeclaration{
    name : String,
    typename : String,
    value : String,
    address: u16
}

struct LabelDeclaration{
    name : String,
    address: u16
}
#[derive(Debug)]
enum Register{
    A,
    B,
    C,
    D,
    E,
    H,
    L,
    None
}
#[derive(Debug,PartialEq)]
enum AluOP{
    Add,
    Sub,   
    None
}
#[derive(Debug)]
struct TypeAInstruction{
    regA: Register,
    regB: Register
}
#[derive(Debug)]
struct Imm8BInstruction{
    regA: Register,
    value: u8
}
#[derive(Debug)]
struct VariableInstruction{
    regA: Register,
    variable : String
}
#[derive(Debug)]
struct ALUInstruction{
    reg: Register,
    operation : AluOP
}
#[derive(Debug)]
enum InstructionType{
    R_LD(TypeAInstruction),
    I_LD(Imm8BInstruction),
    V_LD(VariableInstruction),
    R_ALU(ALUInstruction),
    Other()
}
#[derive(Debug)]
struct InstructionData{
    inst: InstructionType,
    address: u16
}

enum Line{
    Instruction(InstructionData),
    Label(LabelDeclaration),
    Variable(VariableDeclaration)
}

fn string_to_register(name: &str) -> Register
{
    match name {
        "a" => return Register::A,
        "b" => return Register::B,
        "c" => return Register::C,
        "d" => return Register::D,
        "h" => return Register::H,
        "e" => return Register::E,
        "l" => return Register::L,
        _ => return Register::None,
    }
}

fn reg_to_u8(r: &Register) -> u8{
    match r {
        Register::A => return 7,
        Register::B => return 0,
        Register::C => return 1,
        Register::D => return 2,
        Register::E => return 3,
        Register::H => return 4,
        Register::L => return 5,
        Register::None => return 0,
    }
}
fn write_registers(s : &TypeAInstruction) -> u8 {
    let mut v = 0;

    let ra = reg_to_u8(&s.regA);
    let rb = reg_to_u8(&s.regB);

    v |= ra << 3;
    v |= rb << 0;

    return v;
}

fn write_AluInstruction(s : &ALUInstruction) -> u8 {
    let mut u = reg_to_u8(&s.reg);
    let op = match s.operation{
        AluOP::Add => 0,
        AluOP::Sub => 2,
        _ => 7
    };
    let prefix : u8 = 2;

    u |= op << 3;
    u |= prefix << 6;
    return u;
}
fn write_RegInstruction(s : &TypeAInstruction,  prefix: u8) -> u8 {
    let mut u = write_registers(s);
    u |= prefix << 6;
    return u;
}

fn hex_to_u8(s : &str) -> u8 {
    let without_prefix = s.trim_start_matches("0x");
    let z = u8::from_str_radix(without_prefix, 16).unwrap();
    return z;
}

fn get_alu(s : &str) -> AluOP {
   return match s {
       "add" => AluOP::Add,
       "sub" => AluOP::Add,
       _ =>  AluOP::None
   }
}


fn main() {
    let filename = "D:/FPGA/PGB/Programs/vassembler/starter.vasm";
    println!("Opening file {}", filename);
    
    let contents = fs::read_to_string(filename)
        .expect("Something went wrong reading the file");

    let mut variableadresses : HashMap<String, u16> = HashMap::new();
    let mut labeladresses : HashMap<String, u16> = HashMap::new();
    let mut varvalues : Vec<u8> = Vec::new();

    let mut lines : Vec<Line> = Vec::new();

    let mut adresscounter = 0;
    // scan everything


    for mut s in contents.lines() {
        
        let init = &s[0..1];
        if init == "$" 
        {
          
            let restvar = &s[1..];

            let sections  : Vec<&str> = restvar.split(" ").collect();
            if sections.len() < 4 
            {
                println!("BAD VARIABLE DECLARATION {}", s);
            }
            if sections[0] != "byte" || sections[2] != "=" {
                println!("BAD VARIABLE DECLARATION {}", s);
            }
            
            let varname = sections[1];
            let varvalue = sections[3];            
          
            let mut variableDelc = VariableDeclaration{
                name : varname.to_string(), 
                value : varvalue.to_string(), 
                typename : sections[0].to_string(),
                address : adresscounter
            };

            // only bytes now, so +1 on the adresses
            adresscounter = adresscounter+1;

            variableadresses.insert(variableDelc.name.clone(),variableDelc.address);        

            let mut newLine = Line::Variable(variableDelc);           
            lines.push(newLine);
        }
        else if init == ":" //label 
        {
            let mut labelDecl = LabelDeclaration{
                name : s.strip_prefix(":").unwrap().to_string(),                
                address : adresscounter
            };

           

            labeladresses.insert(labelDecl.name.clone(),labelDecl.address);

            let mut newLine = Line::Label(labelDecl);           
            lines.push(newLine);
        }
        else //instruction
        {
            let mut inst = InstructionData{
                address : adresscounter,
                inst : InstructionType::Other()
            };

            let sections  : Vec<&str> = s.split(" ").collect();

            let aluop = get_alu(sections[0]);

            if(sections[0] == "ld")
            {
                if sections[2].contains("$") // variable ld
                {
                    let vars = VariableInstruction{
                        regA: string_to_register(sections[1]),
                        variable : sections[2].strip_prefix("$").unwrap().to_string()
                    };

                    inst.inst = InstructionType::V_LD(vars);

                    adresscounter += 2; // load from memory is a 2 byte instructiuon
                }
                else if sections[2].contains("#") // immediate ld
                {

                    let raw = sections[2].strip_prefix("#").unwrap().to_string();
                   

                    let vars = Imm8BInstruction{
                        regA: string_to_register(sections[1]),
                        value : hex_to_u8(&raw)
                    };

                    inst.inst = InstructionType::I_LD(vars);

                    adresscounter += 2; // load from inst is a 2 byte instructiuon
                }
                else{
                    let vars = TypeAInstruction{
                        regA: string_to_register(sections[1]),
                        regB: string_to_register(sections[2]),
                    };

                    inst.inst = InstructionType::R_LD(vars);

                    adresscounter += 1;
                }
            }
            else if aluop != AluOP::None
            {
                let regA= string_to_register(sections[1]);
                let vars = ALUInstruction{
                    operation: aluop,
                    reg: string_to_register(sections[2]),
                };

                inst.inst = InstructionType::R_ALU(vars);

                adresscounter += 1;
            }

            let mut newLine = Line::Instruction(inst);           
            lines.push(newLine);
        }
    }
    
    let mut bytes : Vec<u8> = Vec::new();

    for l in lines
    {
        match l {
            Line::Instruction(i) => {
                println!("Instruction: address {}, inst {:?}",i.address,  i.inst );
              
                match i.inst {
                    InstructionType::R_LD(a) => bytes.push(write_RegInstruction(&a, 1 )),
                    InstructionType::I_LD(a) => 
                    {
                        match a.regA {
                            Register::A => bytes.push(0x3E),
                            Register::B => bytes.push(0x06),
                            _ => bytes.push(0x00),
                        }
                        
                        bytes.push(a.value);
                    },                    
                    InstructionType::R_ALU(a) => bytes.push(write_AluInstruction(&a)),                                   
                    _ => bytes.push(0x00),
                }
            },
            Line::Label(i) =>  {
                println!("Label: address {}, name {}",i.address, i.name);
            },
            Line::Variable(i) => {
                println!("Variable: address {}, name {}, value {}",i.address, i.name, i.value );
                bytes.push(hex_to_u8(&i.value));
            }    
        }   
    }

    let mut i = 0;
    for b in bytes
    {
        println!("{}:  {:#02x}",i,b);
        i+= 1;
    }
}
