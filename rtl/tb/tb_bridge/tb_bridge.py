import cocotb
from cocotb.triggers import RisingEdge, Combine
from cocotb.clock import Clock
from cocotbext.axi import AxiMaster, AxiBus, AxiStreamSink, AxiStreamSource, AxiStreamBus
from cocotb.binary import BinaryValue

@cocotb.test
async def test(dut):
    cocotb.start_soon(Clock(dut.aclk, 1, units="ns").start())

    axi_master = AxiMaster(AxiBus.from_prefix(dut, "a"), dut.aclk, reset=dut.aresetn, reset_active_level=False)

    axis_master = AxiStreamSource(AxiStreamBus.from_prefix(dut, "b"), dut.aclk, reset=dut.aresetn, reset_active_level=False)
    axis_slave = AxiStreamSink(AxiStreamBus.from_prefix(dut, "a"), dut.aclk, reset=dut.aresetn, reset_active_level=False)

    dut.aresetn.value = 0
    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)
    dut.aresetn.value = 1
    await RisingEdge(dut.aclk)

    axis_rdata = [BinaryValue() for i in range(5)]

    axis_rdata[0].integer = (0b000 << 37) + (0b10 << 4) 
    axis_rdata[1].integer = (0b100 << 37) + int.from_bytes(b'test', "little")
    axis_rdata[2].integer = (0b100 << 37) + int.from_bytes(b'beef', "little")
    axis_rdata[3].integer = (0b000 << 37) + (0b1 << 4) 
    axis_rdata[4].integer = (0b011 << 37)

    task1 = cocotb.start_soon(axi_master.write(0x00000000, b'testbeef', awid=0))
    task2 = cocotb.start_soon(axi_master.read(0x00000000, 8, arid=0))

    for _ in range(10):
        await RisingEdge(dut.aclk)

    for i in range(5):
        await axis_master.send(axis_rdata[i].integer.to_bytes(5, "little"))
        await axis_master.wait()

    await task1
    await task2

    for _ in range(10):
        await RisingEdge(dut.aclk)