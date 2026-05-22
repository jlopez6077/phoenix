import cocotb
from cocotb.clock import Clock 
from cocotb.triggers import RisingEdge, Timer 
import random

# Helper function to safely drive default/idle states
def init_signals(dut):
    dut.s_axis_tdata.value = 0
    dut.s_axis_tvalid.value = 0
    dut.m_axis_tready.value = 0

@cocotb.test()
async def test_phx_axis_width_converter_loop(dut):
    """Test width converter with dynamic data streaming and downstream backpressure loop."""
    
    # 1. Start System Clock (100 MHz / 10ns period)
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # 2. Reset Sequence
    init_signals(dut)
    dut.rst_n.value = 0
    await Timer(20, unit="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    dut._log.info("--- System Reset Released ---")

    # Determine bus dimensions from the design parameters
    in_bytes = int(dut.IN_W.value) // 8
    out_bytes = int(dut.OUT_W.value) // 8
    
    # Define a clean test payload stream (e.g., a simple sequence of bytes)
    test_bytes = list(range(1, 15)) # 64 bytes of test data
    
    # Group raw bytes into IN_W-sized words for the upstream generator
    input_words = []
    for i in range(0, len(test_bytes), in_bytes):
        word = 0
        for b in range(in_bytes):
            if i + b < len(test_bytes):
                word |= (test_bytes[i + b] << (8 * b))
        input_words.append(word)

    # 3. Concurrent Downstream Receiver Loop (Handles m_axis_tready)
    # This coroutine simulates a realistic downstream sink with random stalls
    async def downstream_sink(dut):
        while True:
            await RisingEdge(dut.clk)
            # Simulate backpressure: 80% chance ready is high, 20% chance stall
            dut.m_axis_tready.value = 1 if random.random() < 0.8 else 0
            
            # Optional: If you want a perfectly flat 'always ready' sink instead, use:
            # dut.m_axis_tready.value = 1

    # Spin up the downstream receiver task running in parallel
    cocotb.start_soon(downstream_sink(dut))

    # 4. Upstream Driver Loop (Inserts data and awaits handshakes)
    dut._log.info(f"Starting data injection loop of {len(input_words)} words...")
    
    for word_idx, data_word in enumerate(input_words):
        await RisingEdge(dut.clk)
        
        # Present the word on the bus interface
        dut.s_axis_tdata.value = data_word
        dut.s_axis_tvalid.value = 1
        
        # Loop check: Wait on the rising edge until a valid handshake happens
        # Handshake = s_axis_tvalid && s_axis_tready are both high
        while True:
            await Timer(1, units="ps")
            if dut.s_axis_tready.value == 1:
                break # Handshake successful, word is accepted by the DUT
            await RisingEdge(dut.clk)
            
        dut._log.debug(f"Handshaked Word [{word_idx}]: 0x{data_word:X}")

    # Clear upstream valid signal once all data is sent
    await RisingEdge(dut.clk)
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tdata.value = 0

    # 5. Flush and Cooldown Phase
    # Wait ample clock cycles to ensure narrowing configurations finish draining internal registers
    dut._log.info("Data injection complete. Draining pipeline...")
    for _ in range(20):
        await RisingEdge(dut.clk)

    dut._log.info("--- Test Bench Completed Successfully ---")
