#include "hex_emitter.hpp"

#include <sstream>
#include <vector>
#include <string>
#include <unordered_map>
#include <map>
#include <cstdint>
#include <cstring>
#include <cctype>
#include <iomanip>

namespace
{
    std::string trim(const std::string &s)
    {
        size_t i = 0, j = s.size();
        while (i < j && std::isspace((unsigned char)s[i])) i++;
        while (j > i && std::isspace((unsigned char)s[j - 1])) j--;
        return s.substr(i, j - i);
    }

    std::string upper(std::string s)
    {
        for (char &c : s) c = (char)std::toupper((unsigned char)c);
        return s;
    }

    // Remove colchetes/chaves/virgulas/espacos de um operando: "[R10]" -> "R10"
    std::string limpaOperando(const std::string &s)
    {
        std::string r;
        for (char c : s)
            if (c != '[' && c != ']' && c != '{' && c != '}' && c != ',' && c != ' ' && c != '!')
                r += c;
        return r;
    }

    // ---------- registradores e condicoes ----------

    // Numero do registrador ARM (R0..R15, SP=13, LR=14, PC=15). -1 se invalido.
    int reg(const std::string &raw)
    {
        std::string s = upper(limpaOperando(raw));
        if (s == "SP") return 13;
        if (s == "LR") return 14;
        if (s == "PC") return 15;
        if (s.size() >= 2 && s[0] == 'R')
        {
            try { return std::stoi(s.substr(1)); }
            catch (...) { return -1; }
        }
        return -1;
    }

    // Numero de um registrador VFP double "D0".."D31" (-1 se invalido).
    int dnum(const std::string &raw)
    {
        std::string s = upper(limpaOperando(raw));
        if (s.size() >= 2 && s[0] == 'D')
        {
            try { return std::stoi(s.substr(1)); } catch (...) { return -1; }
        }
        return -1;
    }

    // Numero de um registrador VFP single "S0".."S31" (-1 se invalido).
    int snum(const std::string &raw)
    {
        std::string s = upper(limpaOperando(raw));
        if (s.size() >= 2 && s[0] == 'S')
        {
            try { return std::stoi(s.substr(1)); } catch (...) { return -1; }
        }
        return -1;
    }

    // Quebra um registrador double Dn em (Vd 4 bits, bit alto -> D/N/M).
    void splitD(int n, uint32_t &v4, uint32_t &hi) { v4 = (uint32_t)(n & 0xF); hi = (uint32_t)((n >> 4) & 1); }

    // Quebra um registrador single Sn em (V 4 bits altos, bit baixo -> D/N/M).
    void splitS(int n, uint32_t &v4, uint32_t &lo) { v4 = (uint32_t)((n >> 1) & 0xF); lo = (uint32_t)(n & 1); }

    // Codigo de condicao a partir do sufixo do mnemonico.
    uint32_t cond(const std::string &suf)
    {
        if (suf == "EQ") return 0x0; if (suf == "NE") return 0x1;
        if (suf == "CS" || suf == "HS") return 0x2; if (suf == "CC" || suf == "LO") return 0x3;
        if (suf == "MI") return 0x4; if (suf == "PL") return 0x5;
        if (suf == "VS") return 0x6; if (suf == "VC") return 0x7;
        if (suf == "HI") return 0x8; if (suf == "LS") return 0x9;
        if (suf == "GE") return 0xA; if (suf == "LT") return 0xB;
        if (suf == "GT") return 0xC; if (suf == "LE") return 0xD;
        return 0xE; // AL (sem sufixo)
    }

    // ---------- immediates ----------

    // Le um immediate "#8", "8", "0xFF200000".
    uint32_t parseNum(std::string s)
    {
        s = limpaOperando(s);
        if (!s.empty() && s[0] == '#') s = s.substr(1);
        return (uint32_t)std::stoul(s, nullptr, 0);
    }

    bool ehNumero(const std::string &s)
    {
        std::string t = limpaOperando(s);
        if (!t.empty() && t[0] == '#') t = t.substr(1);
        if (t.empty()) return false;
        return std::isdigit((unsigned char)t[0]) != 0;
    }

    uint32_t rotl32(uint32_t x, unsigned n)
    {
        n &= 31;
        return n == 0 ? x : (x << n) | (x >> (32 - n));
    }

    // Codifica um "modified immediate" (imm8 ror 2*rot). Retorna false se nao cabe.
    bool encodeModImm(uint32_t val, uint32_t &imm12)
    {
        for (uint32_t rot = 0; rot < 16; rot++)
        {
            uint32_t cand = rotl32(val, 2 * rot); // val = ror(cand, 2*rot) => cand = rol(val,2*rot)
            if (cand <= 0xFF)
            {
                imm12 = (rot << 8) | cand;
                return true;
            }
        }
        return false;
    }

    // ---------- modelo do programa ----------

    enum class Sec { NONE, TEXT, DATA };

    struct Instr
    {
        std::string mnem;              // ex.: "LDR", "VADD.F64", "BLE"
        std::vector<std::string> ops;  // operandos ja separados por virgula
        std::string raw;               // linha original (para a listagem)
        uint32_t addr = 0;
    };

    struct DataItem
    {
        enum Kind { LABEL, SPACE, DOUBLE } kind;
        std::string label;   // se LABEL
        uint32_t size = 0;   // se SPACE
        uint64_t bits = 0;   // se DOUBLE (IEEE754)
        double dval = 0.0;   // valor original (listagem)
        uint32_t addr = 0;
    };

    // Separa "MNEM op0, op1, ..." em mnemonico + operandos.
    void splitInstr(const std::string &linha, std::string &mnem, std::vector<std::string> &ops)
    {
        std::string s = trim(linha);
        size_t sp = s.find_first_of(" \t");
        if (sp == std::string::npos) { mnem = s; return; }
        mnem = s.substr(0, sp);
        std::string rest = trim(s.substr(sp));
        std::stringstream ss(rest);
        std::string tok;
        while (std::getline(ss, tok, ','))
            ops.push_back(trim(tok));
    }

    // Formata 'v' como hex maiusculo de 'width' digitos.
    std::string hx(uint32_t v, int width)
    {
        static const char *D = "0123456789ABCDEF";
        std::string s;
        for (int i = width - 1; i >= 0; i--) s += D[(v >> (4 * i)) & 0xF];
        return s;
    }

    // Constroi o arquivo carregavel pelo CPUlator: uma palavra de 32 bits (hex)
    // por linha, contigua a partir de 0x0. Os buracos (ex.: a pilha .space) sao
    // preenchidos com zeros. No CPUlator: endereco inicial 0, tamanho 4 bytes,
    // base hexadecimal.
    std::string buildPlainHex(const std::map<uint32_t, uint8_t> &mem)
    {
        if (mem.empty()) return "";
        uint32_t maxAddr = mem.rbegin()->first;
        std::stringstream h;
        for (uint32_t a = 0; a <= maxAddr; a += 4)
        {
            uint32_t w = 0;
            for (int i = 0; i < 4; i++)
            {
                auto f = mem.find(a + i);
                if (f != mem.end()) w |= (uint32_t)f->second << (8 * i); // little-endian
            }
            h << hx(w, 8) << "\n";
        }
        return h.str();
    }

}

std::string gerarHex(const std::string &assembly, int &naoSuportadas)
{
    naoSuportadas = 0;
    std::map<uint32_t, uint8_t> mem; // imagem de memoria (para o Intel HEX)
    auto putWord = [&](uint32_t addr, uint32_t w)
    { for (int i = 0; i < 4; i++) mem[addr + i] = (uint8_t)((w >> (8 * i)) & 0xFF); };

    std::vector<Instr> code;                       // instrucoes do .text, em ordem
    std::vector<DataItem> data;                    // itens do .data, em ordem
    std::unordered_map<std::string, uint32_t> labelAddr; // label -> endereco (code e data)
    std::vector<std::string> codeLabelsPend;       // labels aguardando proxima instrucao

    // ----- PASSADA A: leitura/parse -----
    Sec sec = Sec::NONE;
    std::stringstream in(assembly);
    std::string linha;
    std::vector<std::pair<std::string, Instr>> textEvents; // ("LBL"/"" , instr)

    while (std::getline(in, linha))
    {
        // remove comentario @...
        size_t at = linha.find('@');
        if (at != std::string::npos) linha = linha.substr(0, at);
        linha = trim(linha);
        if (linha.empty()) continue;

        // extrai label opcional (token terminando em ':')
        std::string label;
        size_t colon = linha.find(':');
        if (colon != std::string::npos)
        {
            label = trim(linha.substr(0, colon));
            linha = trim(linha.substr(colon + 1));
        }

        // diretivas de secao / globais
        std::string low = linha;
        if (!linha.empty() && linha[0] == '.')
        {
            std::string d = upper(linha);
            if (d.rfind(".DATA", 0) == 0) { sec = Sec::DATA; continue; }
            if (d.rfind(".TEXT", 0) == 0) { sec = Sec::TEXT; continue; }
            // .syntax, .global, .arch etc. -> mas pode ter label em data (".space"/".double")
        }

        if (sec == Sec::DATA)
        {
            if (!label.empty())
            {
                DataItem it; it.kind = DataItem::LABEL; it.label = label;
                data.push_back(it);
            }
            if (linha.empty()) continue;
            std::string d = upper(linha);
            if (d.rfind(".SPACE", 0) == 0)
            {
                DataItem it; it.kind = DataItem::SPACE;
                it.size = parseNum(trim(linha.substr(6)));
                data.push_back(it);
            }
            else if (d.rfind(".DOUBLE", 0) == 0)
            {
                DataItem it; it.kind = DataItem::DOUBLE;
                it.dval = std::strtod(trim(linha.substr(7)).c_str(), nullptr);
                std::memcpy(&it.bits, &it.dval, 8);
                data.push_back(it);
            }
            continue;
        }

        // secao .text
        if (sec == Sec::TEXT)
        {
            if (!label.empty()) codeLabelsPend.push_back(label);
            if (linha.empty()) continue;
            if (!linha.empty() && linha[0] == '.') continue; // .global etc.

            Instr ins; ins.raw = linha;
            splitInstr(linha, ins.mnem, ins.ops);
            // associa labels pendentes a esta instrucao
            std::string lbl = codeLabelsPend.empty() ? "" : codeLabelsPend.front();
            for (const std::string &l : codeLabelsPend)
                textEvents.push_back({l, Instr{}}); // marcador de label (instr vazia)
            codeLabelsPend.clear();
            textEvents.push_back({"", ins});
        }
    }

    // ----- PASSADA B: enderecos do .text + labels de codigo -----
    uint32_t addr = 0;
    for (auto &ev : textEvents)
    {
        if (!ev.first.empty() && ev.second.mnem.empty())
        {
            labelAddr[ev.first] = addr; // label aponta para a proxima instrucao
            continue;
        }
        ev.second.addr = addr;
        code.push_back(ev.second);
        addr += 4;
    }
    uint32_t textEnd = addr;

    // ----- literal pool: coleta valores distintos de "LDR Rd,=valor" -----
    std::unordered_map<std::string, uint32_t> poolAddr; // "=valor" -> endereco
    std::vector<std::string> poolOrder;
    for (const Instr &ins : code)
    {
        if (upper(ins.mnem).rfind("LDR", 0) == 0 && ins.ops.size() >= 2)
        {
            std::string v = trim(ins.ops[1]);
            if (!v.empty() && v[0] == '=')
            {
                std::string key = v.substr(1);
                if (poolAddr.find(key) == poolAddr.end())
                {
                    poolAddr[key] = 0; // resolvido abaixo
                    poolOrder.push_back(key);
                }
            }
        }
    }
    uint32_t poolBase = textEnd; // ja alinhado a 4
    for (size_t i = 0; i < poolOrder.size(); i++)
        poolAddr[poolOrder[i]] = poolBase + (uint32_t)i * 4;
    uint32_t poolEnd = poolBase + (uint32_t)poolOrder.size() * 4;

    // ----- PASSADA C: enderecos do .data (alinhado a 8) -----
    uint32_t dataBase = (poolEnd + 7u) & ~7u;
    uint32_t da = dataBase;
    for (DataItem &it : data)
    {
        if (it.kind == DataItem::LABEL) { labelAddr[it.label] = da; it.addr = da; }
        else if (it.kind == DataItem::SPACE) { it.addr = da; da += it.size; }
        else if (it.kind == DataItem::DOUBLE) { it.addr = da; da += 8; }
    }

    // resolve os valores do literal pool (=label -> endereco; =num -> numero)
    std::unordered_map<std::string, uint32_t> poolValue;
    for (const std::string &key : poolOrder)
    {
        if (ehNumero(key)) poolValue[key] = parseNum(key);
        else
        {
            auto f = labelAddr.find(key);
            poolValue[key] = (f != labelAddr.end()) ? f->second : 0u;
        }
    }

    // ----- PASSADA D: codificacao -----
    std::stringstream out;
    auto emitLine = [&](uint32_t a, uint32_t w, const std::string &cmt)
    {
        out << std::hex << std::uppercase << std::setfill('0')
            << std::setw(8) << a << "  " << std::setw(8) << w
            << std::dec << std::nouppercase << "  ; " << cmt << "\n";
    };

    out << "; ==== .text (codigo de maquina ARMv7) ====\n";
    for (const Instr &ins : code)
    {
        std::string M = upper(ins.mnem);
        uint32_t w = 0;
        bool ok = false;

        // ----- Branches: B / BLE / BLT / BGE / B<cond> -----
        if (M == "B" || (M.size() >= 2 && M[0] == 'B' && M != "BL" &&
                         (M == "BEQ" || M == "BNE" || M == "BLT" || M == "BLE" ||
                          M == "BGE" || M == "BGT" || M == "BMI" || M == "BPL" ||
                          M == "BHI" || M == "BLS" || M == "BCS" || M == "BCC")))
        {
            std::string suf = (M == "B") ? "" : M.substr(1);
            auto f = labelAddr.find(trim(ins.ops.empty() ? "" : ins.ops[0]));
            if (f != labelAddr.end())
            {
                int32_t off = (int32_t)f->second - (int32_t)(ins.addr + 8);
                uint32_t imm24 = ((uint32_t)(off >> 2)) & 0xFFFFFF;
                w = (cond(suf) << 28) | (0xA << 24) | imm24;
                ok = true;
            }
        }
        // ----- LDR Rd, =valor  (literal pool) -----
        else if (M == "LDR" && ins.ops.size() >= 2 && !ins.ops[1].empty() &&
                 trim(ins.ops[1])[0] == '=')
        {
            int rt = reg(ins.ops[0]);
            std::string key = trim(ins.ops[1]).substr(1);
            uint32_t slot = poolAddr[key];
            int32_t off = (int32_t)slot - (int32_t)(ins.addr + 8);
            if (rt >= 0 && off >= 0 && off < 4096)
            {
                // LDR (literal), P=1,U=1,W=0, Rn=1111
                w = (0xEu << 28) | (0x59u << 20) | (0xFu << 16) |
                    ((uint32_t)rt << 12) | ((uint32_t)off & 0xFFF);
                ok = true;
            }
        }
        // ----- LDR / STR  Rt, [Rn]  (offset 0) -----
        else if ((M == "LDR" || M == "STR") && ins.ops.size() >= 2)
        {
            int rt = reg(ins.ops[0]);
            int rn = reg(ins.ops[1]);
            if (rt >= 0 && rn >= 0)
            {
                uint32_t L = (M == "LDR") ? 1u : 0u;
                // cond 010 P=1 U=1 0 W=0 L Rn Rt imm12=0
                w = (0xEu << 28) | (0x2u << 25) | (1u << 24) | (1u << 23) |
                    (L << 20) | ((uint32_t)rn << 16) | ((uint32_t)rt << 12);
                ok = true;
            }
        }
        // ----- MOV Rd,#imm  /  MOV(NE) Rd,Rm -----
        else if (M == "MOV" || M == "MOVNE" || M == "MOVEQ")
        {
            std::string suf = (M == "MOV") ? "" : M.substr(3);
            int rd = reg(ins.ops[0]);
            if (rd >= 0 && ins.ops.size() >= 2)
            {
                if (ehNumero(ins.ops[1]))
                {
                    uint32_t imm12;
                    if (encodeModImm(parseNum(ins.ops[1]), imm12))
                    {
                        // DP imm, opcode MOV=1101, S=0
                        w = (cond(suf) << 28) | (1u << 25) | (0xDu << 21) |
                            ((uint32_t)rd << 12) | imm12;
                        ok = true;
                    }
                }
                else
                {
                    int rm = reg(ins.ops[1]);
                    if (rm >= 0)
                    {
                        // DP reg, opcode MOV=1101, S=0, shift 0
                        w = (cond(suf) << 28) | (0xDu << 21) |
                            ((uint32_t)rd << 12) | (uint32_t)rm;
                        ok = true;
                    }
                }
            }
        }
        // ----- LSL Rd, Rm, #sh  (MOV com shift) -----
        else if (M == "LSL" && ins.ops.size() >= 3)
        {
            int rd = reg(ins.ops[0]), rm = reg(ins.ops[1]);
            uint32_t sh = parseNum(ins.ops[2]) & 0x1F;
            if (rd >= 0 && rm >= 0)
            {
                w = (0xEu << 28) | (0xDu << 21) | ((uint32_t)rd << 12) |
                    (sh << 7) | (0u << 5) | (uint32_t)rm;
                ok = true;
            }
        }
        // ----- ADD / SUB  (reg ou imm) -----
        else if (M == "ADD" || M == "SUB")
        {
            uint32_t opc = (M == "ADD") ? 0x4u : 0x2u; // ADD=0100, SUB=0010
            int rd = reg(ins.ops[0]), rn = reg(ins.ops[1]);
            if (rd >= 0 && rn >= 0 && ins.ops.size() >= 3)
            {
                if (ehNumero(ins.ops[2]))
                {
                    uint32_t imm12;
                    if (encodeModImm(parseNum(ins.ops[2]), imm12))
                    {
                        w = (0xEu << 28) | (1u << 25) | (opc << 21) |
                            ((uint32_t)rn << 16) | ((uint32_t)rd << 12) | imm12;
                        ok = true;
                    }
                }
                else
                {
                    int rm = reg(ins.ops[2]);
                    if (rm >= 0)
                    {
                        w = (0xEu << 28) | (opc << 21) | ((uint32_t)rn << 16) |
                            ((uint32_t)rd << 12) | (uint32_t)rm;
                        ok = true;
                    }
                }
            }
        }
        // ----- CMP / TST  Rn, #imm  (S=1, Rd=0) -----
        else if (M == "CMP" || M == "TST")
        {
            uint32_t opc = (M == "CMP") ? 0xAu : 0x8u; // CMP=1010, TST=1000
            int rn = reg(ins.ops[0]);
            if (rn >= 0 && ins.ops.size() >= 2 && ehNumero(ins.ops[1]))
            {
                uint32_t imm12;
                if (encodeModImm(parseNum(ins.ops[1]), imm12))
                {
                    w = (0xEu << 28) | (1u << 25) | (opc << 21) | (1u << 20) |
                        ((uint32_t)rn << 16) | imm12;
                    ok = true;
                }
            }
        }
        // ===================== VFP (double precision) =====================
        // ----- VLDR.F64 Dd, [Rn]  /  VSTR.F64 Dd, [Rn]  (offset 0) -----
        else if ((M == "VLDR.F64" || M == "VSTR.F64") && ins.ops.size() >= 2)
        {
            int dd = dnum(ins.ops[0]), rn = reg(ins.ops[1]);
            if (dd >= 0 && rn >= 0)
            {
                uint32_t Vd, D; splitD(dd, Vd, D);
                uint32_t L = (M == "VLDR.F64") ? (1u << 20) : 0u;
                w = (0xEu << 28) | (0xDu << 24) | (1u << 23) | (D << 22) | L |
                    ((uint32_t)rn << 16) | (Vd << 12) | (0xBu << 8);
                ok = true;
            }
        }
        // ----- VPUSH.F64 {Dd}  /  VPOP.F64 {Dd}  (um double) -----
        else if ((M == "VPUSH.F64" || M == "VPOP.F64") && !ins.ops.empty())
        {
            int dd = dnum(ins.ops[0]);
            if (dd >= 0)
            {
                uint32_t Vd, D; splitD(dd, Vd, D);
                uint32_t base = (M == "VPUSH.F64") ? 0xED2D0B02u : 0xECBD0B02u;
                w = base | (D << 22) | (Vd << 12);
                ok = true;
            }
        }
        // ----- VADD/VSUB/VMUL/VDIV.F64 Dd, Dn, Dm -----
        else if ((M == "VADD.F64" || M == "VSUB.F64" || M == "VMUL.F64" || M == "VDIV.F64") && ins.ops.size() >= 3)
        {
            int dd = dnum(ins.ops[0]), dn = dnum(ins.ops[1]), dm = dnum(ins.ops[2]);
            if (dd >= 0 && dn >= 0 && dm >= 0)
            {
                uint32_t Vd, D, Vn, N, Vm, Mb;
                splitD(dd, Vd, D); splitD(dn, Vn, N); splitD(dm, Vm, Mb);
                uint32_t comum = (0xEu << 28) | (0xEu << 24) | (D << 22) | (Vn << 16) |
                                 (Vd << 12) | (0xBu << 8) | (N << 7) | (Mb << 5) | Vm;
                if (M == "VADD.F64")      w = comum | (0x3u << 20);
                else if (M == "VSUB.F64") w = comum | (0x3u << 20) | (1u << 6);
                else if (M == "VMUL.F64") w = comum | (0x2u << 20);
                else                      w = comum | (1u << 23); // VDIV
                ok = true;
            }
        }
        // ----- VCMP.F64 Dd, Dm -----
        else if (M == "VCMP.F64" && ins.ops.size() >= 2)
        {
            int dd = dnum(ins.ops[0]), dm = dnum(ins.ops[1]);
            if (dd >= 0 && dm >= 0)
            {
                uint32_t Vd, D, Vm, Mb; splitD(dd, Vd, D); splitD(dm, Vm, Mb);
                w = (0xEu << 28) | (0x1Du << 23) | (D << 22) | (0x3u << 20) | (0x4u << 16) |
                    (Vd << 12) | (0xBu << 8) | (1u << 6) | (Mb << 5) | Vm;
                ok = true;
            }
        }
        // ----- VMRS APSR_nzcv, FPSCR  (encoding fixo) -----
        else if (M == "VMRS")
        {
            w = 0xEEF1FA10u;
            ok = true;
        }
        // ----- VMOV: Rt,Sn (2 ops)  ou  Rt,Rt2,Dm (3 ops) -----
        else if (M == "VMOV" && ins.ops.size() == 2)
        {
            int rt = reg(ins.ops[0]), sn = snum(ins.ops[1]);
            if (rt >= 0 && sn >= 0)
            {
                uint32_t Vn, Nb; splitS(sn, Vn, Nb);
                w = (0xEu << 28) | (0xEu << 24) | (1u << 20) | (Vn << 16) |
                    ((uint32_t)rt << 12) | (0xAu << 8) | (Nb << 7) | (1u << 4);
                ok = true;
            }
        }
        else if (M == "VMOV" && ins.ops.size() >= 3)
        {
            int rt = reg(ins.ops[0]), rt2 = reg(ins.ops[1]), dm = dnum(ins.ops[2]);
            if (rt >= 0 && rt2 >= 0 && dm >= 0)
            {
                uint32_t Vm, Mb; splitD(dm, Vm, Mb);
                w = (0xEu << 28) | (0xCu << 24) | (0x5u << 20) | ((uint32_t)rt2 << 16) |
                    ((uint32_t)rt << 12) | (0xBu << 8) | (Mb << 5) | (1u << 4) | Vm;
                ok = true;
            }
        }
        // ----- VCVT.S32.F64 Sd, Dm  (double -> int, round to zero) -----
        else if (M == "VCVT.S32.F64" && ins.ops.size() >= 2)
        {
            int sd = snum(ins.ops[0]), dm = dnum(ins.ops[1]);
            if (sd >= 0 && dm >= 0)
            {
                uint32_t Vd, D, Vm, Mb; splitS(sd, Vd, D); splitD(dm, Vm, Mb);
                w = (0xEu << 28) | (0x1Du << 23) | (D << 22) | (0x3u << 20) | (1u << 19) |
                    (0x5u << 16) | (Vd << 12) | (0xBu << 8) | (1u << 7) | (1u << 6) | (Mb << 5) | Vm;
                ok = true;
            }
        }
        // ----- VCVT.F64.S32 Dd, Sm  (int -> double) -----
        else if (M == "VCVT.F64.S32" && ins.ops.size() >= 2)
        {
            int dd = dnum(ins.ops[0]), sm = snum(ins.ops[1]);
            if (dd >= 0 && sm >= 0)
            {
                uint32_t Vd, D, Vm, Mb; splitD(dd, Vd, D); splitS(sm, Vm, Mb);
                w = (0xEu << 28) | (0x1Du << 23) | (D << 22) | (0x3u << 20) | (1u << 19) |
                    (0x0u << 16) | (Vd << 12) | (0xBu << 8) | (1u << 7) | (1u << 6) | (Mb << 5) | Vm;
                ok = true;
            }
        }

        if (ok)
        {
            emitLine(ins.addr, w, ins.raw);
            putWord(ins.addr, w);
        }
        else
        {
            naoSuportadas++;
            emitLine(ins.addr, 0x00000000u, ins.raw + "   [PENDENTE - fase 2]");
            putWord(ins.addr, 0x00000000u);
        }
    }

    // ----- literal pool -----
    if (!poolOrder.empty())
    {
        out << "; ==== literal pool ====\n";
        for (const std::string &key : poolOrder)
        {
            emitLine(poolAddr[key], poolValue[key], "=" + key);
            putWord(poolAddr[key], poolValue[key]);
        }
    }

    // ----- .data -----
    out << "; ==== .data ====\n";
    for (const DataItem &it : data)
    {
        if (it.kind == DataItem::LABEL)
            out << "; " << it.label << ":\n";
        else if (it.kind == DataItem::SPACE)
        {
            out << std::hex << std::uppercase << std::setfill('0') << std::setw(8)
                << it.addr << std::dec << std::nouppercase
                << "  .space " << it.size << " (zeros)\n";
        }
        else // DOUBLE
        {
            uint32_t lo = (uint32_t)(it.bits & 0xFFFFFFFF);
            uint32_t hi = (uint32_t)(it.bits >> 32);
            out << std::hex << std::uppercase << std::setfill('0') << std::setw(8)
                << it.addr << "  " << std::setw(8) << lo << " " << std::setw(8) << hi
                << std::dec << std::nouppercase << "  ; .double " << it.dval << "\n";
            putWord(it.addr, lo);
            putWord(it.addr + 4, hi);
        }
    }

    return buildPlainHex(mem);
}
