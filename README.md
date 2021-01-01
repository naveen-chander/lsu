# lsu
RTL Description for RISC-V V Spec Load Store Unit <br/>
<ol>
Target Base ISA :RV32I <br/>
SEW ={8,16,32}<br/>
LMUL={1/8,1/4,1/2,1,2,4,8}
To begin with, the data memory bus is 32 bit wide.
Only one element of a vector can be loaded or stored in cycle irrespective of its SEW value.
</ol>
