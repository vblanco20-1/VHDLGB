use std::env;
use std::fs;
use std::collections::HashMap;
use std::u8;
#[derive(Debug,Clone)]
struct VariableDeclaration{
    name : String,
    typename : String,
    value : String,
    address: u16
}
#[derive(Debug,Clone)]
struct LabelDeclaration{
    name : String,
    address: u16
}
#[derive(Debug,Clone)]
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
#[derive(Debug,PartialEq,Clone)]
enum AluOP{
    Add,
    Sub,
    None
}

#[derive(Debug,PartialEq,Clone)]
enum JumpMode{
    Imm,
    NZ,Z,NC,C
}

#[derive(Debug,Clone)]
struct TypeAInstruction{
    regA: Register,
    regB: Register
}
#[derive(Debug,Clone)]
struct Imm8BInstruction{
    regA: Register,
    value: u8
}
#[derive(Debug,Clone)]
struct VariableInstruction{
    regA: Register,
    variable : String
}
#[derive(Debug,Clone)]
struct ALUInstruction{
    reg: Register,
    operation : AluOP
}
#[derive(Debug,Clone)]
struct JumpInstruction{
    label: String,
    mode: JumpMode
}

#[derive(Debug,Clone)]
enum InstructionType{
    Noop(),
    Jmp(JumpInstruction),
    R_LD(TypeAInstruction),
    I_LD(Imm8BInstruction),
    V_LD(VariableInstruction),
    R_ALU(ALUInstruction),
    Other()
}
#[derive(Debug,Clone)]
struct InstructionData{
    inst: InstructionType,
    address: u16
}
#[derive(Clone)]
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

fn reg_to_u8(r: &Register) -> Result<u8,&'static str >{
   return  match r {
        Register::A => Ok(7),
        Register::B => Ok(0),
        Register::C => Ok(1),
        Register::D => Ok(2),
        Register::E => Ok(3),
        Register::H => Ok(4),
        Register::L => Ok(5),
        Register::None => Err("Invalid Register"),
    }
}
fn write_registers(s : &TypeAInstruction) -> Result<u8,&'static str > {
    let mut v = 0;

    let ra = reg_to_u8(&s.regA)?;
    let rb = reg_to_u8(&s.regB)?;

    v |= ra << 3;
    v |= rb << 0;

    return Ok(v);
}

fn write_AluInstruction(s : &ALUInstruction)-> Result<u8,&'static str > {
    let mut u = reg_to_u8(&s.reg)?;
    
    let mut op = 0;
    match s.operation{
        AluOP::Add => {op = 0;},
        AluOP::Sub => {op = 2;},
        _ => { return Err("Invalid alu operation");}
    };
    let prefix : u8 = 2;

    u |= op << 3;
    u |= prefix << 6;
    return Ok(u);
}
fn write_RegInstruction(s : &TypeAInstruction, prefix: u8) -> Result<u8,&'static str > {
    let mut u = write_registers(s)?;
    u |= prefix << 6;
    return Ok(u);
}

fn hex_to_u8(s : &str) -> Result<u8, std::num::ParseIntError>{
    let without_prefix = s.trim_start_matches("0x");
    return u8::from_str_radix(without_prefix, 16);  
}

fn get_alu(s : &str) -> Option<AluOP> {
   return match s {
       "add" => Some(AluOP::Add),
       "sub" => Some(AluOP::Sub),
       _ =>  Option::None
   }
}
fn parse_label(s : &str, address :&mut u16) -> Result<LabelDeclaration,&'static str >
{
    let parsed = s.strip_prefix(":").ok_or("Error parsing label")?;


    let mut labelDecl = LabelDeclaration{
        name : parsed.replace(" ",""),                
        address : *address
    };

    return Ok(labelDecl);           
}

fn parse_variable(s : &str, address :&mut u16) -> Result<VariableDeclaration,&'static str >
{
    let restvar = &s[1..];

    let sections  : Vec<&str> = restvar.split(" ").collect();
    if sections.len() < 4 
    {
        return Err("BAD VARIABLE DECLARATION" );
    }
    if sections[0] != "byte" || sections[2] != "=" {
        return Err("BAD VARIABLE DECLARATION" );
    }
    
    let varname = sections[1];
    let varvalue = sections[3];            
  
    let variableDelc = VariableDeclaration{
        name : varname.to_string(), 
        value : varvalue.to_string(), 
        typename : sections[0].to_string(),
        address : *address
    };

    // only bytes now, so +1 on the adresses
    *address = (*address)+1;

    return Ok(variableDelc);
}

fn parse_jp(line : &str, address:  &mut u16)-> Result<InstructionType,&'static str> {
    let sections  : Vec<&str> = line.split(" ").collect();

    let prefixed = sections[1].strip_prefix(":");

    match prefixed {
        // we are jumping into a label so its immediate mode
        Some(s) => {
            let i = JumpInstruction{
                label: s.to_string(),
                mode: JumpMode::Imm
            };

            *address += 3;

            return Ok(InstructionType::Jmp(i));
        }
        _ => {
           let jumpMode =  match sections[1] {
                "nz" => { Some(JumpMode::NZ)},
                "z" => {  Some(JumpMode::Z)},
                "nc" => {  Some(JumpMode::NC)},
                "c" => {  Some(JumpMode::C)},
                _ => { None}
            };  

            let jumpLabel = sections[2].strip_prefix(":");
            
            if jumpMode.is_some() && jumpLabel.is_some()
            {
                let i = JumpInstruction{
                    label: jumpLabel.unwrap().to_string(),
                    mode: jumpMode.unwrap()
                };
    
                *address += 3;

                return Ok(InstructionType::Jmp(i));
            }
            else{
                return Err("Invalid format of jump instruction");
            }
        }
    }
}

fn parse_op_ld(line : &str, address:  &mut u16) -> Result<InstructionType,&'static str> {
    let sections  : Vec<&str> = line.split(" ").collect();

    if sections[2].contains("$") // variable ld
    {        
        let vars = VariableInstruction{
            regA: string_to_register(sections[1]),
            variable : sections[2].strip_prefix("$").unwrap().to_string()
        };

        *address += 2; // load from memory is a 2 byte instructiuon

        return Ok(InstructionType::V_LD(vars));
    }
    else if sections[2].contains("#") // immediate ld
    {

        let raw = sections[2].strip_prefix("#").unwrap().to_string();
       

        let vars = Imm8BInstruction{
            regA: string_to_register(sections[1]),
            value : hex_to_u8(&raw).unwrap()
        };

       *address += 2; // load from inst is a 2 byte instructiuon

        return  Ok(InstructionType::I_LD(vars));
    }
    else{
        let vars = TypeAInstruction{
            regA: string_to_register(sections[1]),
            regB: string_to_register(sections[2]),
        };

        *address += 1;

        return  Ok(InstructionType::R_LD(vars));       
    }
}

fn assemble_file(filename : &str) -> Result<Vec<u8>,String>
{
   
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
            match parse_variable(s,&mut adresscounter) {
                Ok(v) => {
                      
                    variableadresses.insert(v.name.clone(),v.address);       

                    lines.push(Line::Variable(v));
                },
                Err(error) => {
                    println!("Error when parsing variable {}, {}",s,error);
                }
            }
        }
        else if init == ":" //label 
        { 
            match parse_label(s,&mut adresscounter) {
                Ok(l) => {
                    labeladresses.insert(l.name.clone(),l.address);  
                    lines.push(Line::Label(l));
                },
                Err(error) => {
                    println!("Error when parsing line {}, {}",s,error);
                }
            }
        }
        else if init == "-" // comment
        {
            // literally do nothing
        }
        else //instruction
        {
            let mut inst = InstructionData{
                address : adresscounter,
                inst : InstructionType::Other()
            };

            let sections  : Vec<&str> = s.split(" ").collect();

            let aluop = get_alu(sections[0]);

           
            if aluop.is_some()
            {
                let regA= string_to_register(sections[1]);
                let vars = ALUInstruction{
                    operation: aluop.unwrap(),
                    reg: string_to_register(sections[2]),
                };

                inst.inst = InstructionType::R_ALU(vars);

                adresscounter += 1;
            }
            else{
                match sections[0] {
                    "ld" => { 
                        inst.inst = parse_op_ld(s,&mut adresscounter).unwrap();
                    },
                    "noop" => {

                        inst.inst = InstructionType::Noop();
                        adresscounter += 1;
                    },
                    "jmp" => {
                        inst.inst = parse_jp(s,&mut adresscounter).unwrap();
                    },
                    _ => { 

                        println!("Unrecognized instruction! {}",sections[0]);
                    }
                }
                
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
                    InstructionType::R_LD(a) => bytes.push(write_RegInstruction(&a, 1 ).unwrap()),
                    InstructionType::I_LD(a) => 
                    {
                        match a.regA {
                            Register::A => bytes.push(0x3E),
                            Register::B => bytes.push(0x06),
                            _ => bytes.push(0x00),
                        }
                        
                        bytes.push(a.value);
                    },         
                    InstructionType::Jmp(a) => {
                        let label =labeladresses.get(&a.label);
                       
                        if(label.is_none())
                        {
                            println!("Cant load label adress {}", a.label );

                            for (k,v) in labeladresses.iter()
                            {
                                println!("labels {} {} ", k,v );
                            }
                        }
                        let mem = label.unwrap();
                        match a.mode  {
                            JumpMode::Imm => {
                                
                                bytes.push(0xC3);
                                bytes.push((mem & 0xFF) as u8); // LSB
                                bytes.push(((mem & 0xFF00) >> 2)as u8); // MSB
                            },
                            _ => {
                                bytes.push(
                                    match a.mode {
                                        JumpMode::NZ => 0xC2,
                                        JumpMode::Z=> 0xCA,
                                        JumpMode::NC=> 0xD2,
                                        JumpMode::C => 0xDA,                                        
                                        _ =>0x00
                                    });

                                bytes.push((mem & 0xFF) as u8); // LSB
                                bytes.push(((mem & 0xFF00) >> 2)as u8); // MSB
                            }
                        }

                    },        
                    InstructionType::R_ALU(a) => bytes.push(write_AluInstruction(&a).unwrap()),                                   
                    _ => bytes.push(0x00),
                }
            },
            Line::Label(i) =>  {
                println!("Label: address {}, name {}",i.address, i.name);
            },
            Line::Variable(i) => {
                println!("Variable: address {}, name {}, value {}",i.address, i.name, i.value );
                bytes.push(hex_to_u8(&i.value).unwrap());
            }    
        }   
    }

   return Ok(bytes);
}

fn main() {

    let files = [
        "D:/FPGA/PGB/Programs/vassembler/starter.vasm",
        "D:/FPGA/PGB/Programs/vassembler/microjump.vasm",
        "D:/FPGA/PGB/Programs/vassembler/microloop.vasm"
    ];

    let mut finalbytes : Vec<u8> = Vec::new();
   
   
    let program_size = 16;

    finalbytes.resize(program_size * files.len(), 0);

    let mut offset = 0;
    for f in files.iter(){
        let bytes = assemble_file(f);      

        let mut i = 0;
        for b in bytes.unwrap()
        {
            println!("{}:  {:#04x}",i,b);
            i+= 1;

            finalbytes[i + offset] = b;
        }
        for n in i..program_size
        {            
            println!("{}:  {:#04x}",n,0);
        }

        offset += program_size;
    }

    let mut vhdlarray = "".to_string();

    for b in finalbytes {
        let mut byte = format!("{:#04x}\",",b);
      
        vhdlarray.push_str(&byte.replace("0x","x\""));
    }

    println!("{}",vhdlarray);
}
