module decode(input FETCH,             // first cycle of state machine
              input EXEC1,             // second cycle of state machine
              input EXEC2,             // third cycle of state machine
              input EQ,                // whether value in ACC == N
              input MI,                // whether value in ACC is minus
              input clk,               // clk signal for DFF
              input [3:0] IR,          // opcode of instruction
              output EXTRA,            // control line to state machine for whether EXEC2 is needed
              output Wren,             // Wren for RAM
              output MUX1,
              output MUX3,
              output PC_sload,         // PC = N
              output PC_cnt_en,        // PC + = 1
              output ACC_EN,           // enable ACC for shift and load
              output ACC_LOAD,         // when ACC_EN is high, do shift if ACC_LOAD = 0, do load if ACC_LOAD = 
              output ACC_SHIFTIN,      // value append when shifting value of ACC
              output ADDSUB,           // 1 for add, 0 for sub
              output MUX3_useAllBits, // whether all 16bits from RAM need to be loaded to ACC
              output pipeline_State);
    // assign value for opcode
    assign LDA = !IR[3] & !IR[2] & !IR[1] & !IR[0];
    assign STA = !IR[3] & !IR[2] & !IR[1] & IR[0];
    assign ADD = !IR[3] & !IR[2] & IR[1] & !IR[0];
    assign SUB = !IR[3] & !IR[2] & IR[1] & IR[0];
    assign JMP = !IR[3] & IR[2] & !IR[1] & !IR[0];
    assign JMI = !IR[3] & IR[2] & !IR[1] & IR[0];
    assign JEQ = !IR[3] & IR[2] & IR[1] & !IR[0];
    assign STP = !IR[3] & IR[2] & IR[1] & IR[0];
    assign LDI = IR[3] & !IR[2] & !IR[1] & !IR[0];
    assign LSR = IR[3] & !IR[2] & IR[1] & !IR[0];
    assign ASR = IR[3] & !IR[2] & IR[1] & IR[0];
    // assign pipeline related var
    assign canPipeline_np = LDA & EXEC2 | LDI & EXEC1 | ADD & EXEC2 | SUB & EXEC2 | LSR & EXEC1 | ASR & EXEC1;
    assign canPipeline_p  = LDA & EXEC1 | LDI & FETCH | ADD & EXEC1 | SUB & EXEC1 | LSR & FETCH | ASR & FETCH;
    assign canPipeline    = canPipeline_np | canPipeline_p & BeenPipelined;
    // assign BeenPipelined = 0;
    // instantiate 1-bit DFF for pipeline state
    RisingEdge_DFF pipelineState(
    .D (canPipeline),
    .clk (clk),
    .Q (BeenPipelined)
    );
    // assign conditions for each control line
    assign EXTRA           = LDA & EXEC1 | ADD & EXEC1 | SUB & EXEC1;
    
    assign Wren_np         = STA & EXEC1;
    assign Wren_p          = STA & FETCH;
    assign Wren            = Wren_np | Wren_p & BeenPipelined;

    assign MUX1_np         = LDA & EXEC1 | STA & EXEC1 | ADD & EXEC1 | SUB & EXEC1;
    assign MUX1_p          = LDA & FETCH | STA & FETCH | ADD & FETCH | SUB & FETCH;
    assign MUX1            = MUX1_np | MUX1_p & BeenPipelined;

    assign MUX3_np         = LDA & EXEC2 | LDI & EXEC1;
    assign MUX3_p          = LDA & EXEC1 | LDI & FETCH;
    assign MUX3            = MUX3_np | MUX1_p & BeenPipelined;

    assign PC_sload_np     = JMP & EXEC1 | JMI & EXEC1 & MI | JEQ & EXEC1 & EQ;
    assign PC_sload_p      = JMP & FETCH | JMI & FETCH & MI | JEQ & FETCH & EQ;
    assign PC_sload        = PC_sload_np | PC_sload_p & BeenPipelined;
    
    assign PC_cnt_en_np    = LDA & EXEC2 | STA & EXEC1 | ADD & EXEC2 | SUB & EXEC2 | JMI & EXEC1 & !MI | JEQ & EXEC1 & !EQ | LDI & EXEC1 | LSR & EXEC1 | ASR & EXEC1;
    // assign PC_cnt_en_p     = LDA & EXEC1 | STA & FETCH | ADD & EXEC1 | SUB & EXEC1 | JMI & FETCH & !MI | JEQ & FETCH & !EQ | LDI & FETCH | LSR & FETCH | ASR & FETCH;
    assign PC_cnt_en       = PC_cnt_en_np | canPipeline;
    
    assign ACC_EN_np       = LDA & EXEC2 | ADD & EXEC2 | SUB & EXEC2 | LDI & EXEC1 | LSR & EXEC1 | ASR & EXEC1;
    assign ACC_EN_p        = LDA & EXEC1 | ADD & EXEC1 | SUB & EXEC1 | LDI & FETCH | LSR & FETCH | ASR & FETCH;
    assign ACC_EN          = ACC_EN_np | ACC_EN_p & BeenPipelined;
    
    assign ACC_LOAD_np     = LDA & EXEC2 | ADD & EXEC2 | SUB & EXEC2 | LDI & EXEC1;
    assign ACC_LOAD_p      = LDA & EXEC1 | ADD & EXEC1 | SUB & EXEC1 | LDI & FETCH;
    assign ACC_LOAD        = ACC_LOAD_np | ACC_LOAD_p & BeenPipelined;
    
    assign ADDSUB_np       = ADD & EXEC2;
    assign ADDSUB_p        = ADD & EXEC1;
    assign ADDSUB          = ADDSUB_np | ADDSUB_p & BeenPipelined;
    // assign ACC_SHIFTIN  = LSR & EXEC1;
    assign ACC_SHIFTIN_np  = ASR & EXEC1 & MI;
    assign ACC_SHIFTIN_p   = ASR & FETCH & MI;
    assign ACC_SHIFTIN     = ACC_SHIFTIN_np | ACC_SHIFTIN_p & BeenPipelined;
    // assign ACC_SHIFTIN  = 0;
    assign MUX3_useAllBits_np = LDA & EXEC2 | LSR & EXEC1 | ASR & EXEC1;
    assign MUX3_useAllBits_p  = LDA & EXEC1 | LSR & FETCH | ASR & FETCH;
    assign MUX3_useAllBits    = MUX3_useAllBits_np | MUX3_useAllBits_p & BeenPipelined;
    // debug for the value of pipeline state
    assign pipeline_State = BeenPipelined;
endmodule
    // Verilog code for D Flip FLop
    module RisingEdge_DFF(D,clk,Q);
        input D; // Data input
        input clk; // clock input
        output reg Q; // output Q
        always @(posedge clk)
        begin
            Q <= D;
        end
    endmodule
