onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib DMEM_opt

do {wave.do}

view wave
view structure
view signals

do {DMEM.udo}

run -all

quit -force
