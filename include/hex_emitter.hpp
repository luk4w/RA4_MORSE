#ifndef HEX_EMITTER_HPP
#define HEX_EMITTER_HPP
#include <string>

// Monta o Assembly ARMv7 (texto) em codigo de maquina e retorna o hexadecimal:
// uma palavra de 32 bits (8 digitos hex) por linha, contiguo a partir de 0x0, little-endian (os buracos, como a pilha .space, viram zeros).
// Carregavel no CPUlator: Load memory from file (endereco inicial 0, tamanho do elemento 4 bytes, base hexadecimal).
// naoSuportadas conta instrucoes sem encoder.
std::string gerarHex(const std::string &assembly, int &naoSuportadas);

#endif
