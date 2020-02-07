/**
 *  Name:
 *    bp_be_dcache_pkt.vh
 *
 *  Description:
 *    dcache packet format to be sent from mmu.
 */

`ifndef BP_BE_DCACHE_PKT_VH
`define BP_BE_DCACHE_PKT_VH

`define declare_bp_be_dcache_pkt_s(page_offset_width_mp, data_width_mp) \
  typedef struct packed {                                      \
    bp_be_dcache_opcode_e opcode;                              \
    logic [page_offset_width_mp-1:0] page_offset;              \
    logic [data_width_mp-1:0] data;                            \
  } bp_be_dcache_pkt_s

`define bp_be_dcache_pkt_width(page_offset_width_mp, data_width_mp) \
  ($bits(bp_be_dcache_opcode_e)+page_offset_width_mp+data_width_mp)
/*
// Cache Service Interface - Cache miss message type

typedef enum [2:0]
{
  e_miss_load          = 3'b000
  , e_miss_store       = 3'b001
  , e_uc_load          = 3'b010
  , e_uc_store         = 3'b011
  , e_wt_store         = 3'b100
  , e_block_read_resp  = 3'b101
} bp_cache_miss_msg_type_e;

// Cache Service Interface - Cache miss size

typedef enum logic [2:0]
{
  e_size_1B     = 3'b000
  , e_size_2B   = 3'b001
  , e_size_4B   = 3'b010
  , e_size_8B   = 3'b011
  , e_size_16B  = 3'b100
  , e_size_32B  = 3'b101
  , e_size_64B  = 3'b110
} bp_cache_miss_size_e;

// Cache Service Interface - Cache miss structure

`define declare_bp_cache_miss_s(data_width_mp, ways_mp, paddr_width_mp) \
 typedef struct packed                             \
 {                                                 \
   logic [data_width_mp-1:0] data;                 \
   logic [`BSG_SAFE_CLOG2(ways_mp)-1:0] repl_way;  \
   logic dirty;                                    \
   bp_cache_miss_size_e size;                      \
   logic [paddr_width_mp-1:0] addr;                \
   bp_cache_miss_msg_type_e msg_type;              \
 } bp_cache_miss_s

`define bp_cache_miss_width(data_width_mp, ways_mp, paddr_width_mp) \
 (data_width_mp+ways_mp+1+$bits(bp_cache_miss_size_e) \
 +paddr_width_mp+$bits(bp_cache_miss_msg_type_e))

`define declare_bp_cache_miss_widths(data_width_mp, ways_mp, paddr_width_mp) \
 , localparam bp_cache_miss_width_lp = `bp_cache_miss_width(data_width_mp, ways_mp, paddr_width_mp)
*/
`endif
