#pragma once

/* base opcode flags (by table) */ 
#define OP_NONE           0x000
#define OP_DATA_I8        0x001
#define OP_DATA_I16       0x002
#define OP_DATA_I32       0x004
#define OP_MODRM          0x008
#define OP_DATA_PRE66_67  0x010
#define OP_PREFIX         0x020
#define OP_REL32          0x040
#define OP_REL8           0x080

/* extended opcode flags (by analyzer) */
#define OP_EXTENDED       0x100

unsigned long size_of_code(unsigned char *code);
unsigned long x_code_flags(unsigned char *code);