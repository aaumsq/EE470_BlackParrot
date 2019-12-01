

// TODO: This module is identical to bp_remote_domain_proxy_node modulo the address map.
//   Maybe there's a clever way to get around this, like proxying out for the address map only
module bp_host_remote_domain_proxy_node
 import bp_common_pkg::*;
 import bp_common_aviary_pkg::*;
 import bp_be_pkg::*;
 import bp_common_cfg_link_pkg::*;
 import bp_cce_pkg::*;
 import bsg_noc_pkg::*;
 import bsg_wormhole_router_pkg::*;
 import bp_me_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_inv_cfg
   `declare_bp_proc_params(bp_params_p)
   `declare_bp_me_if_widths(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p)

   , localparam mem_noc_ral_link_width_lp = `bsg_ready_and_link_sif_width(mem_noc_flit_width_p)
   )
  (input                                                clk_i
   , input                                              reset_i

   , input [mem_noc_did_width_p-1:0]                    my_did_i
   , input [mem_noc_cord_width_p-1:0]                   my_cord_i

   , input [mem_noc_ral_link_width_lp-1:0]              on_cmd_link_i
   , output [mem_noc_ral_link_width_lp-1:0]             on_cmd_link_o

   , input [mem_noc_ral_link_width_lp-1:0]              on_resp_link_i
   , output [mem_noc_ral_link_width_lp-1:0]             on_resp_link_o

   , input [E:W][mem_noc_ral_link_width_lp-1:0]         off_cmd_link_i
   , output [E:W][mem_noc_ral_link_width_lp-1:0]        off_cmd_link_o

   , input [E:W][mem_noc_ral_link_width_lp-1:0]         off_resp_link_i
   , output [E:W][mem_noc_ral_link_width_lp-1:0]        off_resp_link_o
   );

  `declare_bp_me_if(paddr_width_p, cce_block_width_p, lce_id_width_p, lce_assoc_p);
  `declare_bsg_ready_and_link_sif_s(mem_noc_flit_width_p, mem_noc_ral_link_s);
  `declare_bp_mem_wormhole_payload_s(mem_noc_did_width_p, mem_noc_cord_width_p, mem_noc_cid_width_p, cce_mem_msg_width_lp, mem_cmd_payload_s);
  `declare_bp_mem_wormhole_payload_s(mem_noc_did_width_p, mem_noc_cord_width_p, mem_noc_cid_width_p, cce_mem_msg_width_lp, mem_resp_payload_s);
  `declare_bsg_wormhole_interdomain_packet_s(mem_noc_cord_width_p, mem_noc_len_width_p, mem_noc_cid_width_p, mem_noc_did_width_p, $bits(mem_cmd_payload_s), mem_cmd_packet_s);
  `declare_bsg_wormhole_interdomain_packet_s(mem_noc_cord_width_p, mem_noc_len_width_p, mem_noc_cid_width_p, mem_noc_did_width_p, $bits(mem_resp_payload_s), mem_resp_packet_s);

  mem_noc_ral_link_s [S:N] stub_cmd_li, stub_cmd_lo;
  mem_noc_ral_link_s rtr_cmd_link_li, rtr_cmd_link_lo;
  assign stub_cmd_li = '0;
  bsg_wormhole_router
   #(.flit_width_p(mem_noc_flit_width_p)
     ,.dims_p(mem_noc_dims_p)
     ,.cord_dims_p(mem_noc_dims_p)
     ,.cord_markers_pos_p(mem_noc_cord_markers_pos_p)
     ,.len_width_p(mem_noc_len_width_p)
     ,.reverse_order_p(0)
     ,.routing_matrix_p(StrictXY)
     )
   cmd_router
   (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.my_cord_i(mem_noc_cord_width_p'(my_did_i))
    ,.link_i({stub_cmd_li, off_cmd_link_i, rtr_cmd_link_li})
    ,.link_o({stub_cmd_lo, off_cmd_link_o, rtr_cmd_link_lo})
    );

  mem_noc_ral_link_s [S:N] stub_resp_li, stub_resp_lo;
  mem_noc_ral_link_s rtr_resp_link_li, rtr_resp_link_lo;
  assign stub_resp_li = '0;
  bsg_wormhole_router
   #(.flit_width_p(mem_noc_flit_width_p)
     ,.dims_p(mem_noc_dims_p)
     ,.cord_dims_p(mem_noc_dims_p)
     ,.cord_markers_pos_p(mem_noc_cord_markers_pos_p)
     ,.len_width_p(mem_noc_len_width_p)
     ,.reverse_order_p(0)
     ,.routing_matrix_p(StrictXY)
     )
   resp_router
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.my_cord_i(mem_noc_cord_width_p'(my_did_i))
     ,.link_i({stub_resp_li, off_resp_link_i, rtr_resp_link_li})
     ,.link_o({stub_resp_lo, off_resp_link_o, rtr_resp_link_lo})
     );

  mem_cmd_packet_s on_mem_cmd_packet_li, on_mem_cmd_packet_lo;
  logic on_mem_cmd_v_li, on_mem_cmd_ready_lo;
  logic on_mem_cmd_v_lo, on_mem_cmd_yumi_li;
  bsg_wormhole_router_adapter
   #(.max_payload_width_p($bits(mem_cmd_payload_s)+mem_noc_cid_width_p+mem_noc_did_width_p)
     ,.len_width_p(mem_noc_len_width_p)
     ,.cord_width_p(mem_noc_cord_width_p)
     ,.flit_width_p(mem_noc_flit_width_p)
     )
   on_cmd_adapter
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.packet_i(on_mem_cmd_packet_li)
     ,.v_i(on_mem_cmd_v_li)
     ,.ready_o(on_mem_cmd_ready_lo)

     ,.link_i(on_cmd_link_i)
     ,.link_o(on_cmd_link_o)

     ,.packet_o(on_mem_cmd_packet_lo)
     ,.v_o(on_mem_cmd_v_lo)
     ,.yumi_i(on_mem_cmd_yumi_li)
     );
  mem_cmd_payload_s on_mem_cmd_payload_lo;
  assign on_mem_cmd_payload_lo = on_mem_cmd_packet_lo.payload;

  mem_resp_packet_s on_mem_resp_packet_li, on_mem_resp_packet_lo;
  logic on_mem_resp_v_li, on_mem_resp_ready_lo;
  logic on_mem_resp_v_lo, on_mem_resp_yumi_li;
  bsg_wormhole_router_adapter
   #(.max_payload_width_p($bits(mem_resp_payload_s)+mem_noc_cid_width_p+mem_noc_did_width_p)
     ,.len_width_p(mem_noc_len_width_p)
     ,.cord_width_p(mem_noc_cord_width_p)
     ,.flit_width_p(mem_noc_flit_width_p)
     )
   on_resp_adapter
    (.clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.packet_i(on_mem_resp_packet_li)
      ,.v_i(on_mem_resp_v_li)
      ,.ready_o(on_mem_resp_ready_lo)

      ,.link_i(on_resp_link_i)
      ,.link_o(on_resp_link_o)

      ,.packet_o(on_mem_resp_packet_lo)
      ,.v_o(on_mem_resp_v_lo)
      ,.yumi_i(on_mem_resp_yumi_li)
      );
  mem_resp_payload_s on_mem_resp_payload_lo;
  assign on_mem_resp_payload_lo = on_mem_resp_packet_lo.payload;

  mem_cmd_packet_s off_mem_cmd_packet_li, off_mem_cmd_packet_lo;
  logic off_mem_cmd_v_li, off_mem_cmd_ready_lo;
  logic off_mem_cmd_v_lo, off_mem_cmd_yumi_li;
  bsg_wormhole_router_adapter
   #(.max_payload_width_p($bits(mem_cmd_payload_s)+mem_noc_cid_width_p+mem_noc_did_width_p)
     ,.len_width_p(mem_noc_len_width_p)
     ,.cord_width_p(mem_noc_cord_width_p)
     ,.flit_width_p(mem_noc_flit_width_p)
     )
   off_cmd_adapter
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.packet_i(off_mem_cmd_packet_li)
     ,.v_i(off_mem_cmd_v_li)
     ,.ready_o(off_mem_cmd_ready_lo)

     ,.link_i(rtr_cmd_link_lo)
     ,.link_o(rtr_cmd_link_li)

     ,.packet_o(off_mem_cmd_packet_lo)
     ,.v_o(off_mem_cmd_v_lo)
     ,.yumi_i(off_mem_cmd_yumi_li)
     );
  mem_cmd_payload_s off_mem_cmd_payload_lo;
  assign off_mem_cmd_payload_lo = off_mem_cmd_packet_lo.payload;

  mem_resp_packet_s off_mem_resp_packet_li, off_mem_resp_packet_lo;
  logic off_mem_resp_v_li, off_mem_resp_ready_lo;
  logic off_mem_resp_v_lo, off_mem_resp_yumi_li;
  bsg_wormhole_router_adapter
   #(.max_payload_width_p($bits(mem_resp_payload_s)+mem_noc_cid_width_p+mem_noc_did_width_p)
     ,.len_width_p(mem_noc_len_width_p)
     ,.cord_width_p(mem_noc_cord_width_p)
     ,.flit_width_p(mem_noc_flit_width_p)
     )
   off_resp_adapter
    (.clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.packet_i(off_mem_resp_packet_li)
      ,.v_i(off_mem_resp_v_li)
      ,.ready_o(off_mem_resp_ready_lo)

      ,.link_i(rtr_resp_link_lo)
      ,.link_o(rtr_resp_link_li)

      ,.packet_o(off_mem_resp_packet_lo)
      ,.v_o(off_mem_resp_v_lo)
      ,.yumi_i(off_mem_resp_yumi_li)
      );
  mem_resp_payload_s off_mem_resp_payload_lo;
  assign off_mem_resp_payload_lo = off_mem_resp_packet_lo.payload;

  bp_cce_mem_msg_s off_mem_cmd_lo;
  assign off_mem_cmd_lo = off_mem_cmd_payload_lo.data;
  wire [paddr_width_p-1:0] local_cmd_addr_li = off_mem_cmd_lo.addr;

  // TODO Attach host and fake memory to router coordinates
  //wire host_not_dram = (mem_cmd_lo.addr < dram_base_addr_gp);
  wire [mem_noc_cord_width_p-1:0] cmd_dst_cord_lo = '0; 
  wire [mem_noc_cord_width_p-1:0] cmd_dst_cid_lo  = '0;

  always_comb
    begin
      // On-chip to off-chip
      on_mem_cmd_yumi_li              = on_mem_cmd_v_lo & off_mem_cmd_ready_lo;
      off_mem_cmd_v_li                = on_mem_cmd_yumi_li;

      off_mem_cmd_packet_li           = on_mem_cmd_packet_lo;
      off_mem_cmd_packet_li.did       = on_mem_cmd_packet_lo.did;
      off_mem_cmd_packet_li.cord      = on_mem_cmd_packet_lo.did;
      off_mem_cmd_packet_li.cid       = '0;

      on_mem_resp_yumi_li             = on_mem_resp_v_lo & off_mem_resp_ready_lo;
      off_mem_resp_v_li               = on_mem_resp_yumi_li;

      off_mem_resp_packet_li          = on_mem_resp_packet_lo;
      off_mem_resp_packet_li.did      = on_mem_resp_payload_lo.src_did;
      off_mem_resp_packet_li.cord     = on_mem_resp_payload_lo.src_did;
      off_mem_resp_packet_li.cid      = '0;

      // Off-chip to on-chip
      off_mem_cmd_yumi_li             = off_mem_cmd_v_lo & on_mem_cmd_ready_lo;
      on_mem_cmd_v_li                 = off_mem_cmd_yumi_li;

      on_mem_cmd_packet_li            = off_mem_cmd_packet_lo;
      on_mem_cmd_packet_li.did        = off_mem_cmd_packet_lo.did;
      on_mem_cmd_packet_li.cord       = cmd_dst_cord_lo;
      on_mem_cmd_packet_li.cid        = cmd_dst_cid_lo;

      off_mem_resp_yumi_li            = off_mem_resp_v_lo & on_mem_resp_ready_lo;
      on_mem_resp_v_li                = off_mem_resp_yumi_li;

      on_mem_resp_packet_li           = off_mem_resp_packet_lo;
      on_mem_resp_packet_li.did       = off_mem_resp_payload_lo.src_did;
      on_mem_resp_packet_li.cord      = off_mem_resp_payload_lo.src_cord;
      on_mem_resp_packet_li.cid       = off_mem_resp_payload_lo.src_cid;
    end

endmodule
