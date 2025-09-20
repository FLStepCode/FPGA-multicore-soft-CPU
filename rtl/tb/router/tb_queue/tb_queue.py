import cocotb
from cocotb.triggers import RisingEdge, Event
from cocotb.clock import Clock
from cocotbext.axi import AxiStreamSource, AxiStreamSink, AxiStreamBus, AxiStreamFrame
from cocotb.handle import Force, Release

@cocotb.test
async def test_queue(dut):

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    axis_source = AxiStreamSource(
        AxiStreamBus.from_prefix(dut, "m"),
        dut.clk, reset=dut.rst_n,
        reset_active_level=False
        )

    axis_sink = AxiStreamSink(
        AxiStreamBus.from_prefix(dut, "s"),
        dut.clk, reset=dut.rst_n,
        reset_active_level=False
        )

    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    frame = AxiStreamFrame(
        b'I fucked you bullshit shit',
        tx_complete=Event()
        )
    await axis_source.send(frame)
    await frame.tx_complete.wait()
    print(frame.tx_complete.data.sim_time_start)

    for _ in range(10):
        await RisingEdge(dut.clk)

