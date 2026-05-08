import cocotb
from cocotb.clock import Clock 
from cocotb.triggers import RisingEdge, Timer 
import random

@cocotb.test()
async def test_phx_axil_register_basic(dut):
    """Test Register Read/Write AXI4-Lite Commands on axil_register design"""

    # Parameters from hardware

    # Start the clock (100MHz = 10ns period)
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0

    # Reset the device
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    dut._log.info("--- Reset Released ---")
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    

    await RisingEdge(dut.clk)
    dut._log.info("--- Simulation Finished ---")
