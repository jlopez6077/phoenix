import cocotb
from cocotb.clock import Clock 
from cocotb.triggers import RisingEdge, Timer 
import random

@cocotb.test()
async def test_phx_bypass_basic(dut):
    """Test phx_bypass with random data and check latency"""

    # Parameters from hardware
    width = int(dut.WIDTH.value)
    dina_delay = int(dut.DINA_DELAY.value)
    dinb_delay = int(dut.DINB_DELAY.value)
    reg_out = int(dut.REGISTER_OUTPUT.value)

    # Start the clock (100MHz = 10ns period)
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.sw.value = 0
    dut.dina.value = 0
    dut.dinb.value = 0

    # Reset the device
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    dut._log.info("--- Reset Released ---")
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    
    # Testing dina, sw = 0
    val_a = 0xA1
    dut.dina.value = val_a
    dut.sw.value = 0
    expected_cycles = dina_delay + reg_out
    dut._log.info(f"Setting dina={hex(val_a)}. Expected at dout in {expected_cycles} cycles.")

    for _ in range(expected_cycles):
        await RisingEdge(dut.clk)

    await Timer(1, unit="ps") # Small delay to avoid race conditions
    actual = int(dut.dout.value)
    assert actual == val_a, f"FAILURE: Expected {hex(val_a)}, Actual {hex(actual)}"
    dut._log.info("SUCCESS: dina reached dout")
    
    # Testing dinb (sw = 1)
    await RisingEdge(dut.clk)
    val_b = 0xB2
    dut.sw.value = 1
    dut.dinb.value = val_b
    expected_cycles = dinb_delay + reg_out
    dut._log.info(f"Setting dinb={hex(val_b)}. Expected at dout in {expected_cycles} cycles.")

    for _ in range(expected_cycles):
        await RisingEdge(dut.clk)

    await Timer(1, unit="ps")
    actual = int(dut.dout.value)
    assert actual == val_b, f"FAILURE: Expected {hex(val_b)}, Actual {hex(actual)}"
    dut._log.info("SUCCESS: dinb reached dout correctly.")

    # Final Test Loop (Randomized)
    dut._log.info("--- Starting Randomized Loop ---")
    for i in range(5):
        await RisingEdge(dut.clk)
        new_sw = random.randint(0, 1)
        new_a = random.randint(0, (2**width)-1)
        new_b = random.randint(0, (2**width)-1)

        dut.sw.value = new_sw
        dut.dina.value = new_a
        dut.dinb.value = new_b

        expected = new_b if new_sw else new_a
        delay = (dinb_delay if new_sw else dina_delay) + reg_out

        # Wait for the path latency
        if delay > 0:
            for _ in range(delay):
                await RisingEdge(dut.clk)

        await Timer(1, unit="ps")
        actual = int(dut.dout.value)
        assert actual == expected, f"Loop {i} FAILURE: sw={new_sw}, Expected {hex(expected)}, Actual {hex(actual)}"
        dut._log.info(f"Loop {i} SUCCESS: sw={new_sw}, dout={hex(actual)}")

    await RisingEdge(dut.clk)
    dut._log.info("--- Simulation Finished ---")
