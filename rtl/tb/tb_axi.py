import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotbext.axi import AxiMaster, AxiBus

@cocotb.test()
async def axi_test(dut):
    clock = Clock(dut.ACLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    axi_master = AxiMaster(AxiBus.from_prefix(dut, ""), dut.ACLK, reset=dut.ARESETn, reset_active_level=False)

    dut.WSTRB.value = 0xF

    dut.ARESETn.value = 0
    await RisingEdge(dut.ACLK)
    await RisingEdge(dut.ACLK)
    dut.ARESETn.value = 1
    await RisingEdge(dut.ACLK)

    await axi_master.write(0x00000000, b'test')

    await axi_master.read(0x00000000, 4)

    for _ in range(10):
        await RisingEdge(dut.ACLK)