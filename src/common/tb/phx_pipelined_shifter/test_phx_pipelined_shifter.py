import cocotb
from cocotb.clock import Clock 
from cocotb.triggers import RisingEdge, Timer 

# --- MAIN TEST ---
@cocotb.test()
async def test_phx_pipelined_shifter_basic(dut):
    # Start clock
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.shift_in.value = 0xDEADBEEF00000000
    dut.shift_amt.value = 0x20

    await Timer(100, unit="ns")
