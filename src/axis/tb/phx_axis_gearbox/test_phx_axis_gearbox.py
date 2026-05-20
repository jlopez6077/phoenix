import cocotb
from cocotb.clock import Clock 
from cocotb.triggers import RisingEdge, Timer 

# --- MAIN TEST ---
@cocotb.test()
async def test_phx_axis_gearbox_basic(dut):
    # Start clock
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset sequence
    dut.rst_n.value = 0
    await Timer(20, unit="ns")
    dut.rst_n.value = 1
    dut._log.info("--- Reset Released ---")
    
    await RisingEdge(dut.clk)
    dut.s_axis_tdata.value = 0x0201
    dut.s_axis_tvalid.value = 1
    await RisingEdge(dut.clk)
    dut.s_axis_tdata.value = 0x0403
    await RisingEdge(dut.clk)
    dut.s_axis_tdata.value = 0x0605
    await RisingEdge(dut.clk)
    dut.s_axis_tdata.value = 0x0807

    await Timer(100, unit="ns")
    dut._log.info("--- Test Successful ---")
    
