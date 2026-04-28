import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

@cocotb.test()
async def test_delay_line_basic(dut):
    """Test phx_delay_line with random data and check latency"""

    # 1. Start the clock (100MHz = 10ns period)
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # 2. Reset the device
    dut.rst_n.value = 0
    dut.din.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # 3. Drive stimulus
    latency = int(dut.LATENCY.value)
    for _ in range(20):
        val = random.randint(0, (2**int(dut.WIDTH.value)) - 1)
        dut.din.value = val
        
        # Wait for the configured latency cycles
        if latency > 0:
            for _ in range(latency):
                await RisingEdge(dut.clk)
        
        # Add a tiny delay to let signals settle after the edge
        await Timer(1, unit="ps") 
        
        # 4. Check the output
        actual = dut.dout.value
        assert actual == val, f"Error: Expected {hex(val)}, got {hex(actual)}"
        dut._log.info(f"Success: Input {hex(val)} matches Output {hex(actual)}")
