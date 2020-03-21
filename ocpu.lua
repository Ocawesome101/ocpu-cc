-- ocpu emulator --

local regs = require("registers")
local cpuio = require("cpuio")
local mem = require("memory")

local interruptVectors = {
  [0x0] = nil, -- timer
  [0x1] = nil, -- double fault
  [0x2] = nil -- keypress
}

local function setInterruptVector(v, a)
  interruptVectors[v] = a 
end

local maxnum = 0xFFFFFFFF -- the highest 32-bit integer

local inst = {
  [0x00] = function(reg, data) -- load 
    regs.set(reg, data)
  end,
  [0x01] = function(reg, addr) -- memload
    regs.set(reg, mem.get(addr))
  end,
  [0x10] = function(reg, addr) -- store
    mem.set(addr, regs.get(reg))
  end,
  [0x20] = function(reg, data) -- add
    local added = regs.get(reg) + data
    if added > maxnum then
      added = added - maxnum
    end
    regs.set(reg, added)
  end,
  [0x21] = function(reg, reg2) -- regadd
    local added = regs.get(reg) + regs.get(reg2)
    if added > maxnum then
      added = added - maxnum
    end
    regs.set(reg, added)
  end,
  [0x30] = function(reg, data) -- sub
    local subbed = regs.get(reg) - regs.get(reg2)
    if subbed < 0 then
      subbed = maxnum - subbed
    end
    regs.set(reg, subbed)
  end,
  [0x31] = function(reg, reg2) -- regsub
    local subbed = regs.get(reg) - regs.get(reg2)
    if subbed < 0 then
      subbed = maxnum - subbed
    end
    regs.set(reg, subbed)
  end,
  [0x40] = function(dest, reg, reg2) -- check equal
    regs.set(dest, (regs.get(reg) == regs.get(reg2) and 0) or 1)
  end,
  [0x41] = function(dest, reg, reg2) -- check not equal
    regs.set(dest, (regs.get(reg) ~= regs.get(reg2) and 0) or 1)
  end,
  [0x42] = function(dest, reg, reg2) -- check greater than
    regs.set(dest, (regs.get(reg) > regs.get(reg2) and 0) or 1)
  end,
  [0x43] = function(dest, reg, reg2) -- check less than
    regs.set(dest, (regs.get(reg) < regs.get(reg2) and 0) or 1)
  end,
  [0x50] = function(_, offset) -- jump
    setProgramCounter(offset)
  end,
  [0x51] = function(reg, offset) -- jump if zero
    if regs.get(reg) == 0 then
      setProgramCounter(offset)
    end
  end,
  [0x52] = function(reg, offset) -- jump if not zero
    if regs.get(reg) ~= 0 then
      setProgramCounter(offset)
    end
  end,
  [0x53] = function(reg) -- get program counter
    regs.set(reg, getProgramCounter())
  end,
  [0x60] = function(_, page) -- page set 
    mem.setCurrentPage(page)
  end,
  [0x61] = function(reg) -- page get
    regs.set(reg, mem.getCurrentPage())
  end, 
  [0x70] = function(interrupt, offset) -- set interrupt vector 
    setInterruptVector(interrupt, offset)
  end,
  [0x71] = function(dest, dest2) -- get last interrupt data
    regs.set(dest, getInterruptCode())
    regs.set(dest2, getInterruptData())
  end,
  [0x80] = function(addr, signal) -- send IO signal
    serial.sendSignal(addr, signal)
  end
}
