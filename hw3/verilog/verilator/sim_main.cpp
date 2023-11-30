#include <verilated.h>
#include <verilated_vcd_c.h>

#include <algorithm>
#include <fstream>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "VTop.h"  // From Verilating "top.v"

class Memory {
private:
    std::vector<uint32_t> memory;
    
public:
    Memory(size_t size) : memory(size, 0) {}
    
    uint32_t* image() {
        return &(memory[0]);
    }
    
    uint32_t read(size_t address) {
        address = address / 4;
        if (address >= memory.size())
            return 0;

        return memory[address];
    }

    void write(size_t address, uint32_t value, bool write_strobe[4]) {
        address = address / 4;
        uint32_t write_mask = 0;
        if (write_strobe[0])
            write_mask |= 0x000000FF;
        if (write_strobe[1])
            write_mask |= 0x0000FF00;
        if (write_strobe[2])
            write_mask |= 0x00FF0000;
        if (write_strobe[3])
            write_mask |= 0xFF000000;
        if (address >= memory.size())
            return;
        memory[address] =
            (memory[address] & ~write_mask) | (value & write_mask);
    }
    
    void load_binary(std::string const &filename, size_t load_address = 0x1000) {
        std::ifstream file(filename, std::ios::binary);
        if (!file)
            throw std::runtime_error("Failed to open file " + filename);
        file.seekg(0, std::ios::end);
        size_t size = file.tellg();
        if (load_address + size > memory.size() * 4) {
            throw std::runtime_error(
                "File " + filename + " is too large (File is " +
                std::to_string(size) + " bytes. Memory is " +
                std::to_string(memory.size() * 4 - load_address) + " bytes. Load address is)" + 
                std::to_string(load_address) + ").");
        }
        file.seekg(0, std::ios::beg);
        for (int i = 0; i < size / 4; ++i)
            file.read(reinterpret_cast<char *>(&memory[i + load_address / 4]),
                      sizeof(uint32_t));
    }
};

class VRAM {
private:
    std::vector<uint32_t> vram;
    bool vram_dirty = true;
    
public:
    static constexpr uint32_t ROWS = 20;
    static constexpr uint32_t COLS = 80/4;
    static constexpr uint32_t SPACE = 0x20202020;
    
    VRAM() : vram(ROWS * COLS, SPACE) {
        std::cout << std::string(ROWS + 1, '\n');
        flush();
        vram_dirty = false;
    }
    
    uint32_t* image() {
        return &(vram[0]);
    }
    
    uint32_t read(size_t address) {
        address = address / 4;
        if (address >= vram.size())
            return 0;

        return vram[address];
    }

    void write(size_t address, uint32_t value, bool write_strobe[4]) {
        address = address / 4;
        uint32_t write_mask = 0;
        if (write_strobe[0])
            write_mask |= 0x000000FF;
        if (write_strobe[1])
            write_mask |= 0x0000FF00;
        if (write_strobe[2])
            write_mask |= 0x00FF0000;
        if (write_strobe[3])
            write_mask |= 0xFF000000;
        if (address >= vram.size())
            return;
        vram[address] =
            (vram[address] & ~write_mask) | (value & write_mask);
        vram_dirty = true;
    }
    
    void flush() {
        if (! vram_dirty) {
            return;
        }
        vram_dirty = false;
        std::cout << "\x1b[A";
        for(uint32_t i=0; i<ROWS; i++) {
            std::cout << "\x1b[A\x1b[2K";
        }
        std::cout << std::flush;
        for(uint32_t i=0; i<ROWS; i++) {
            for(uint32_t j=0; j<COLS; j++) {
                uint32_t val = vram[i * COLS + j];
                char ch0 = (char) ((val >>  0) & 0xff);
                char ch1 = (char) ((val >>  8) & 0xff);
                char ch2 = (char) ((val >> 16) & 0xff);
                char ch3 = (char) ((val >> 24) & 0xff);
                std::cout << ch0 << ch1 << ch2 << ch3;
            }
            std::cout << "\n";
        }
        std::cout << "\x1b[B" << std::flush;
    }
};

class Printer {
private:
    uint32_t s_row = 0;
    uint32_t s_col = 0;
    VRAM &vram;
    void write_char(uint32_t row, uint32_t col, unsigned char ch) {
        bool strobe[4] = {false, false, false, false};
        uint32_t offset = col % 4;
        strobe[offset] = true;
        vram.write(row * VRAM::COLS * 4 + col, ch << (offset * 8), strobe);
    }
public:
    Printer(VRAM &vram) : vram(vram) {}
    void copy_line(uint32_t dst, uint32_t src) {
        for (uint32_t i = 0; i < VRAM::COLS * 4; i+=4) {
            uint32_t val = vram.read(src * VRAM::COLS * 4 + i);
            bool strobe[4] = {true, true, true, true};
            vram.write(dst * VRAM::COLS * 4 + i, val, strobe);
        }
    }
    void new_line() {
        s_col = 0;
        if (s_row == VRAM::ROWS - 1) {
            for (uint32_t i = 0; i < VRAM::ROWS - 1; i++) {
                copy_line(i, i + 1);
            }
            for (uint32_t i = 0; i < VRAM::COLS * 4; i+=4) {
                bool strobe[4] = {true, true, true, true};
                vram.write((VRAM::ROWS - 1) * VRAM::COLS * 4 + i, VRAM::SPACE, strobe);
            }
        } else {
            s_row ++;
        }
    }
    void putch(unsigned char ch) {
        if (ch == '\n') {
            new_line();
        } else if (ch == '\r') {
            s_col = 0;
        } else {
            if (s_col == VRAM::COLS *4 - 1)
                new_line();
            write_char(s_row, s_col, ch);
            s_col ++;
        }
    }
    void clear_screen() {
        s_row = 0;
        s_col = 0;
        for (uint32_t i = 0; i < VRAM::ROWS * VRAM::COLS * 4; i+=4) {
            bool strobe[4] = {true, true, true, true};
            vram.write(i, VRAM::SPACE, strobe);
        }
    }
    void print_string(const char *str, size_t size) {
        const char *strend = str + size;
        while(str < strend) {
            putch(*str);
            str ++;
        }
    }
};

class InterruptHandler {
private:
    Memory &memory;
    VRAM &vram;
    Printer printer;
public:
    InterruptHandler(Memory &memory, VRAM &vram) : memory(memory), vram(vram), printer(vram) {}
    
    uintptr_t memoryTranslate(uint32_t src) {
        if(src < 0x20000000) {
            return (uintptr_t) (((char *) memory.image()) + src);
        }
        else if(src < 0x40000000) {
            return (uintptr_t) (((char *) vram.image()) + src - 0x20000000);
        }
        else {
            return 0;
        }
    }
    
    void handle(uint32_t type, uint32_t arg0, uint32_t arg1, uint32_t arg2, uint32_t arg3, uint32_t arg4, uint32_t arg5) {
        if(type == 64) {
            printer.print_string((char *)memoryTranslate(arg1), arg2);
        }
    }
};

class VCDTracer {
private:
    VerilatedVcdC *tfp = nullptr;
    
public:
    void enable(std::string const &filename, VTop &top) {
        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC;
        top.trace(tfp, 99);
        tfp->open(filename.c_str());
        tfp->set_time_resolution("1ps");
        tfp->set_time_unit("1ns");
        if (!tfp->isOpen())
            throw std::runtime_error("Failed to open VCD dump file " +
                                     filename);
    }

    void dump(vluint64_t time) {
        if (tfp)
            tfp->dump(time);
    }

    ~VCDTracer() {
        if (tfp) {
            tfp->close();
            delete tfp;
        }
    }
};

uint32_t parse_number(std::string const &str) {
    if (str.size() > 2) {
        auto &&prefix = str.substr(0, 2);
        if (prefix == "0x" || prefix == "0X")
            return std::stoul(str.substr(2), nullptr, 16);
    }
    return std::stoul(str);
}

class Simulator {
private:
    vluint64_t main_time = 0;
    vluint64_t max_sim_time = 10000;
    uint32_t halt_address = 0;
    size_t memory_words = 1024 * 1024;  // 4MiB
    bool dump_vcd = false;
    std::unique_ptr<VTop> top;
    std::unique_ptr<VCDTracer> vcd_tracer;
    std::unique_ptr<Memory> memory;
    std::unique_ptr<VRAM> vram;
    std::unique_ptr<InterruptHandler> ihandler;
    bool dump_signature = false;
    unsigned long signature_begin, signature_end;
    std::string signature_filename;
    std::string instruction_filename;

public:
    void parse_args(std::vector<std::string> const &args) {
        if (auto it = std::find(args.begin(), args.end(), "-halt");
            it != args.end()) {
            halt_address = parse_number(*(it + 1));
        }

        if (auto it = std::find(args.begin(), args.end(), "-memory");
            it != args.end()) {
            memory_words = parse_number(*(it + 1));
        }

        if (auto it = std::find(args.begin(), args.end(), "-time");
            it != args.end()) {
            max_sim_time = std::stoull(*(it + 1));
        }

        if (auto it = std::find(args.begin(), args.end(), "-vcd");
            it != args.end()) {
            vcd_tracer->enable(*(it + 1), *top);
        }

        if (auto it = std::find(args.begin(), args.end(), "-signature");
            it != args.end()) {
            dump_signature = true;
            signature_begin = parse_number(*(it + 1));
            signature_end = parse_number(*(it + 2));
            signature_filename = *(it + 3);
        }

        if (auto it = std::find(args.begin(), args.end(), "-instruction");
            it != args.end()) {
            instruction_filename = *(it + 1);
        }
        
    }

    Simulator(std::vector<std::string> const &args)
            : top(std::make_unique<VTop>()),
            vcd_tracer(std::make_unique<VCDTracer>()) {
        parse_args(args);
        
        std::cout << "-time " << max_sim_time << std::endl
                  << "-memory " << memory_words << std::endl
                  << "-instruction " << instruction_filename << std::endl;
        
        memory = std::make_unique<Memory>(memory_words);
        vram = std::make_unique<VRAM>();
        ihandler = std::make_unique<InterruptHandler>(*memory, *vram);
        if (!instruction_filename.empty())
            memory->load_binary(instruction_filename);
    }

    void run() {
        top->reset = 1;
        top->clock = 0;
        top->eval();
        vcd_tracer->dump(main_time);
        uint32_t data_memory_read_word = 0;
        uint32_t inst_memory_read_word = 0;
        uint32_t counter = 0;
        uint32_t clocktime = 1;
        bool memory_write_strobe[4] = {false};
        bool vram_write_strobe[4] = {false};
        
        std::cout << std::endl;
        int last_percentage = -1;
        int ecall_timeout = 0;
        
        while (main_time < max_sim_time && !Verilated::gotFinish()) {
            ++main_time;
            ++counter;
            if (counter > clocktime) {
                top->clock = !top->clock;
                counter = 0;
            }
            if (main_time > 2)
                top->reset = 0;

            top->io_instruction_valid = 1;
            top->io_memory_bundle_read_data = data_memory_read_word;
            top->io_instruction = inst_memory_read_word;
            top->clock = !top->clock;
            top->eval();

            data_memory_read_word = memory->read(top->io_memory_bundle_address);
            inst_memory_read_word = memory->read(top->io_instruction_address);

            if (top->io_memory_bundle_write_enable) {
                memory_write_strobe[0] = top->io_memory_bundle_write_strobe_0;
                memory_write_strobe[1] = top->io_memory_bundle_write_strobe_1;
                memory_write_strobe[2] = top->io_memory_bundle_write_strobe_2;
                memory_write_strobe[3] = top->io_memory_bundle_write_strobe_3;
                memory->write(top->io_memory_bundle_address,
                              top->io_memory_bundle_write_data,
                              memory_write_strobe);
            }
            if (top->io_vram_bundle_write_enable) {
                vram_write_strobe[0] = top->io_vram_bundle_write_strobe_0;
                vram_write_strobe[1] = top->io_vram_bundle_write_strobe_1;
                vram_write_strobe[2] = top->io_vram_bundle_write_strobe_2;
                vram_write_strobe[3] = top->io_vram_bundle_write_strobe_3;
                vram->write(top->io_vram_bundle_address,
                              top->io_vram_bundle_write_data,
                              vram_write_strobe);
            }
            if (top->io_ecall_en) {
                if(ecall_timeout == 0) {
                    ihandler->handle(top->io_ecall_a7, top->io_ecall_a0, top->io_ecall_a1, top->io_ecall_a2,
                                top->io_ecall_a3, top->io_ecall_a4, top->io_ecall_a5);
                    ecall_timeout = 3;
                }
                else {
                    ecall_timeout --;
                }
            }
            vcd_tracer->dump(main_time);
            if (halt_address) {
                if (memory->read(halt_address) == 0xBABECAFE) {
                    std::cout << "halted after " << main_time << " time\n";
                    break;
                }
            }
            
            vram->flush();
            
            /* show progress */
            int percentage = (double) main_time * 100 / max_sim_time;
            if (percentage > last_percentage) {
                last_percentage = percentage;
                std::cout << "\x1b[A[" << std::string(percentage / 5, '-')
                          << ">" << std::string(20 - percentage / 5, ' ')
                          << "] " << percentage << "%" << std::endl;
            }
        }

        if (dump_signature) {
            char data[9] = {0};
            std::ofstream signature_file(signature_filename);
            for (size_t addr = signature_begin; addr < signature_end;
                 addr += 4) {
                snprintf(data, 9, "%08x", *(uint32_t *) ihandler->memoryTranslate(addr));
                signature_file << data << std::endl;
            }
        }
    }

    ~Simulator() {
        if (top)
            top->final();
    }
};

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    std::vector<std::string> args(argv, argv + argc);
    Simulator simulator(args);
    simulator.run();
    return 0;
}
