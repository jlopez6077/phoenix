# Project     : Fpga-based Deterministic Packet Engine
# Author      : Juan Lopez
# Created     : 2026-08-16

# ------------------------------------------------------------------------------
# phx_axis_frame_controller Python Testbench
# ------------------------------------------------------------------------------
import cocotb
from cocotb.clock import Clock 
from cocotb.triggers import RisingEdge, Timer 

import random

s_valid_injection = 1.0 # Duty cycle for s_axis_tvalid 
m_ready_injection = 1.0 # Duty cycle for m_axis_tready


async def axis_upstream(dut, input_data):
    for data in input_data:
        while random.random() > s_valid_injection:
            dut.s_axis_tvalid.value = 0
            await RisingEdge(dut.axis_clk)
        
        dut.s_axis_tvalid.value = 1
        dut.s_axis_tdata.value = data

        while True:
            await RisingEdge(dut.axis_clk)
            if dut.s_axis_tready.value == 1 and dut.s_axis_tvalid.value == 1:
                break
    dut.s_axis_tvalid.value = 0

async def axis_downstream(dut, captured_data, expected_count):
    while len(captured_data) < expected_count:
        while random.random() > m_ready_injection:
            dut.m_axis_tready.value = 0 
            await RisingEdge(dut.axis_clk)
        dut.m_axis_tready.value = 1
        await RisingEdge(dut.axis_clk)

        if dut.m_axis_tready.value == 1 and dut.m_axis_tvalid.value == 1:
            captured_data.append(int(dut.m_axis_tdata.value))

    dut.m_axis_tready.value = 0

# Helper function default state
def init_signals(dut):
    dut.s_axis_tdata.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tlast.value = 0

# --- MAIN TEST ---
@cocotb.test()
async def phx_axis_frame_controller_basic(dut):
    """phx_axis_frame_controller Cocotb Testbench"""
    global s_valid_injection, m_ready_injection
    # Start clock
    clock = Clock(dut.axis_clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset sequence
    init_signals(dut)
    dut.rst_n.value = 0
    await Timer(20, unit="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.axis_clk)
    dut._log.info("--- Reset Released ---")

    # Start testbench here ---
    dut.s_axis_tvalid.value = 1
    dut.m_axis_tready.value = 1
   
    tx_data = [random.randint(0,0xFFFFFFFF) for _ in range(50)]
    rx_data = []

    upstream_task = cocotb.start_soon(axis_upstream(dut,tx_data))
    downstream_task = cocotb.start_soon(axis_downstream(dut,rx_data, expected_count=len(tx_data)))

    await upstream_task
    await downstream_task

    assert(tx_data == rx_data), f"Mismatch!\nSent: {tx_data}\nReceived {rx_data}"

    rx_data.clear()
    
    s_valid_injection = 0.5 # Duty cycle for s_axis_tvalid 

    upstream_task = cocotb.start_soon(axis_upstream(dut,tx_data))
    downstream_task = cocotb.start_soon(axis_downstream(dut,rx_data, expected_count=len(tx_data)))
    await upstream_task
    await downstream_task 

    assert(tx_data == rx_data), f"Mismatch!\nSent: {tx_data}\nReceived {rx_data}"

    rx_data.clear()
    s_valid_injection = 1.0 
    m_ready_injection = 0.5 

    upstream_task = cocotb.start_soon(axis_upstream(dut,tx_data))
    downstream_task = cocotb.start_soon(axis_downstream(dut,rx_data, expected_count=len(tx_data)))
    await upstream_task
    await downstream_task
    tx_hex = [f"0x{val:08X}" for val in tx_data]
    rx_hex = [f"0x{val:08X}" for val in rx_data]
    assert(tx_data == rx_data), f"Mismatch!\nSent: {tx_hex}\nReceived {rx_hex}"

    rx_data.clear()
    s_valid_injection = 0.5 
    m_ready_injection = 0.5 

    upstream_task = cocotb.start_soon(axis_upstream(dut,tx_data))
    downstream_task = cocotb.start_soon(axis_downstream(dut,rx_data, expected_count=len(tx_data)))
    await upstream_task
    await downstream_task
    assert(tx_data == rx_data), f"Mismatch!\nSent: {tx_data}\nReceived {rx_data}"

    for _ in range(5):
      await RisingEdge(dut.axis_clk)
    dut._log.info("--- Simulation Finished ---")
