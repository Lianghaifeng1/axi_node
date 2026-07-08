//include seqence file
`include "./axi_crossbar_test_base_seq.sv"
`include "./axi_crossbar_axi_vip_seq_lib.sv"

//include virtual sequence file
`include "./axi_crossbar_test_base_vseq.sv"
`include "./virtual_sequence/axi_crossbar_test_vseq.sv"
`include "./virtual_sequence/axi_crossbar_test_reg_vseq.sv"
`include "./virtual_sequence/axi_crossbar_test_stress_vseq.sv"
`include "./virtual_sequence/cpu_wrapper_axi_hub_smoke_vseq.sv"
