import cocotb
from cocotb.clock import Clock 
from cocotb.triggers import RisingEdge, Timer 

# --- MAIN TEST ---
@cocotb.test()
async def test_phx_pipelined_shifter_basic(dut):
    # Start clock
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 1
    dut.enable.value = 1
    dut.shift_in.value = 0xD1CC4A5500000000
    dut.shift_valid.value = 1
    dut.shift_amt.value = 0x20
        # A B C D E F 1 0 5
    await Timer(100, unit="ns")
