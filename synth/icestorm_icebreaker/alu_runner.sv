
module alu_runner;

  reg CLK;
  reg BTN_N = 1;
  logic RX;
  logic TX;

  logic [7:0] data_to_send_i;
  logic [7:0] data_received_o;
  logic tx_ready_o, tx_valid_i, rx_ready_i, rx_valid_o;
  logic rst_ni = 1;

  initial begin
    CLK = 0;
    forever begin
      #41.666ns;  // 12MHz
      CLK = !CLK;
    end
  end

  logic pll_out;
  initial begin
    pll_out = 0;
    forever begin
      #16.393ns;  // 30.5MHz
      pll_out = !pll_out;
    end
  end
  assign icebreaker.pll.PLLOUTGLOBAL = pll_out;

  icebreaker icebreaker (.*);

  uart_tx #(
      .DATA_WIDTH(8)
  ) uart_tx_inst (
      .clk(pll_out),
      .rst(!rst_ni),
      .s_axis_tdata(data_to_send_i),
      .s_axis_tready(tx_ready_o),
      .s_axis_tvalid(tx_valid_i),
      .prescale(33),
      .txd(RX),
      .busy()
  );

  uart_rx #(
      .DATA_WIDTH(8)
  ) uart_rx_inst (
      .clk(pll_out),
      .rst(!rst_ni),
      .m_axis_tdata(data_received_o),
      .m_axis_tready(rx_ready_i),
      .m_axis_tvalid(rx_valid_o),
      .prescale(33),
      .rxd(TX),
      .busy(),
      .frame_error(),
      .overrun_error()
  );

  task automatic reset;
    BTN_N <= 0;
    @(posedge CLK);
    BTN_N <= 1;
  endtask

  task automatic send(input logic [7:0] data);
    while (!tx_ready_o) @(posedge CLK);
    data_to_send_i <= data;
    tx_valid_i <= 1;
    @(posedge CLK);
    tx_valid_i <= 0;
  endtask

  task automatic receive(output logic [7:0] data);
    while (!rx_valid_o) @(posedge CLK);
    rx_ready_i <= 1;
    data = data_received_o;
    @(posedge CLK);
    rx_ready_i <= 0;
    @(posedge CLK);
  endtask

endmodule
