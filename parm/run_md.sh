#!/bin/bash

###pre-work###
/bin/cat > tleap.in<<EOF
source oldff/leaprc.ff99SB
source leaprc.water.tip3p
source leaprc.phosaa10
loadamberparams frcmod.ions1lm_126_tip3p    
source leaprc.gaff
loadamberparams LEP.frcmod 
loadamberparams SAM_resp.frcmod 
loadoff sam.lib
LEP = loadmol2 LEP.mol2 
mol = loadpdb 6ix9_chainB_proton_SAM_TS-1.pdb
solvateBox mol TIP3PBOX 10.0
addions mol Na+ 0
addions mol Na+ 70
addions mol Cl- 70
savepdb mol 6ix9_complex_solv.pdb  
saveamberparm mol min.prmtop min.inpcrd
EOF
tleap -f tleap.in >tleap.log


mkdir min
cp min.prmtop min.inpcrd ./min
cd min

############################


###Full Minimize###
/bin/cat > min.in<<mEOF
initial minimisation whole system
 &cntrl
  imin   = 1,
  maxcyc = 10000,
  ncyc   = 20000,
  ntb    = 1,             
  ntr    = 0,            
  cut    = 10.0
 /
mEOF
mpirun -np 4 sander.MPI -O -i min.in -o min.out -p min.prmtop -c min.inpcrd -r min.nrst


############################
cd ..


mkdir heating
cp min.prmtop min/min.nrst heating/
cd heating
/bin/cat > heat.in<<hEOF
ACD-KTP : initial minimisation solvent
 &cntrl
  imin   = 0,
  ig     = -1,  
  irest  = 0,  
  ntx    = 1,   
  ntb    = 1,   
  cut    = 10.0,
  ntr    = 0,   
  ntc    = 2,   
  ntf    = 2,   
  ntxo   = 2,   
  tempi  = 0.0,
  temp0  = 300.0,
  ntt    = 3,
  nmropt = 1,
  gamma_ln = 1.0,    
  nstlim = 175000, dt = 0.002,                     
  ntpr = 1000, ntwe = 0, ntwr = 1000, 
 /
 
&wt
  type  = 'TEMP0', istep1=0, istep2=25000, value1=0.0, value2=50.0
 /

&wt
  type  = 'TEMP0', istep1=25001, istep2=50000, value1=50.0, value2=100.0
 /
 
&wt
  type  = 'TEMP0', istep1=50001, istep2=75000, value1=100.0, value2=150.0
 /
 
&wt
  type  = 'TEMP0', istep1=75001, istep2=100000, value1=150.0, value2=200.0
 /
 
&wt
  type  = 'TEMP0', istep1=100001, istep2=125000, value1=200.0, value2=250.0
 /
 
&wt
  type  = 'TEMP0', istep1=125001, istep2=150000, value1=250.0, value2=300.0
 /

&wt
  type  = 'TEMP0', istep1=150001, istep2=175000, value1=300.0, value2=300.0
 /
 
&wt
  type  = 'END'
 /
 
hEOF
CUDA_VISIBLE_DEVICES=0 pmemd.cuda_SPFP -O -i heat.in -o heat.out -p min.prmtop -c min.nrst -r heat.nrst

############################
cd ..

mkdir equil
cp min.prmtop heating/heat.nrst equil/
cd equil

/bin/cat > equil.in<<eEOF
BCD-KTP : initial minimisation whole system
 &cntrl
  imin   = 0,
  ig     = -1,
  irest  = 1,
  ntx    = 5,
  ntb    = 2,
  pres0  = 1.0,
  ntp    = 1,
  taup   = 2.0,
  cut    = 10.0,
  ntr    = 0,
  nmropt = 1,
  ntc    = 2,
  ntf    = 2,
  ntxo   = 2,
  tempi  = 300.0,
  temp0  = 300.0,
  ntt    = 3,
  gamma_ln = 2.0,
  nstlim = 100000, dt = 0.002,
  ntpr = 1000, ntwx = 1000, ntwr = 1000,
 /

&wt 
  type   = 'END'
 /
 
LISTOUT = POUT
DISANG = ../rst.dist
eEOF
CUDA_VISIBLE_DEVICES=0 pmemd.cuda_SPFP -O -i equil.in -o equil.out -p min.prmtop -c heat.nrst -r equil.nrst -x equil.mdcrd

/bin/cat > equil2.in<<mEOF
BCD-KTP : initial minimisation whole system
 &cntrl
  imin   = 0,
  ig     = -1,
  irest  = 1,
  ntx    = 5,
  ntb    = 2,
  pres0  = 1.0,
  ntp    = 1,
  taup   = 2.0,
  cut    = 10.0,
  ntr    = 0,
  nmropt = 1,
  ntc    = 2,
  ntf    = 2,
  ntxo   = 2,
  tempi  = 300.0,
  temp0  = 300.0,
  ntt    = 3,
  gamma_ln = 2.0,
  nstlim = 100000, dt = 0.002,
  ntpr = 1000, ntwx = 1000, ntwr = 1000,
 /

&wt 
  type   = 'END'
 /
 
LISTOUT = POUT
DISANG = ../rst.dist
mEOF
CUDA_VISIBLE_DEVICES=0 pmemd.cuda_SPFP -O -i equil2.in -o equil2.out -p min.prmtop -c equil.nrst -r equil2.nrst -x equil2.mdcrd

/bin/cat > equil3.in<<pEOF
BCD-KTP : initial minimisation whole system
 &cntrl
  imin   = 0,
  ig     = -1,
  irest  = 1,
  ntx    = 5,
  ntb    = 1,
  ntp    = 0,
  cut    = 10.0,
  ntr    = 0,
  nmropt = 1,
  ntc    = 2,
  ntf    = 2,
  ntxo   = 2,
  tempi  = 300.0,
  temp0  = 300.0,
  ntt    = 3,
  gamma_ln = 2.0,
  nstlim = 1000000, dt = 0.002,
  ntpr = 1000, ntwx = 1000, ntwr = 1000,
 /

&wt 
  type   = 'END'
 /
 
LISTOUT = POUT
DISANG = ../rst.dist
pEOF
CUDA_VISIBLE_DEVICES=0 pmemd.cuda_SPFP -O -i equil3.in -o equil3.out -p min.prmtop -c equil2.nrst -r equil3.nrst -x equil3.mdcrd

cd ..

mkdir produc_0
cp min.prmtop equil/equil3.nrst produc_0/
cd produc_0

######Production simulation stage###
/bin/cat > 04Production.in<<EOF
Production simulation
 &cntrl
  imin   = 0,
  ig     = -1,
  irest  = 0,
  ntx    = 5,
  ntb    = 1,
  pres0  = 1.0,
  ntp    = 0,
  cut    = 10.0,
  ntr    = 0,
  ntc    = 2,
  nmropt = 1,
  ntf    = 2,
  ntxo   = 2,
  tempi  = 300.0,
  temp0  = 300.0,
  ntt    = 1,
  ioutfm = 1,
  nstlim = 20000000, dt = 0.002,
  ntpr = 25000, ntwx = 25000, ntwr = 50000,
 /
 
  
 &wt 
  type   = 'END'
 /
 
LISTOUT = POUT
DISANG = ../rst.dist
EOF
CUDA_VISIBLE_DEVICES=0 pmemd.cuda_SPFP -O -i 04Production.in -o 04Production.out -p min.prmtop -c equil3.nrst -r 04Production.nrst -x 04Production.mdcrd

mv 04Production.nrst Production_0.nrst 

cd ..

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
do
j=$[i-1]
mkdir produc_$i
cp produc_$j/Production_$j.nrst  ./produc_$i
cp min.prmtop  ./produc_$i
cd produc_$i

/bin/cat > Production.in<<EOF
Production simulation
 &cntrl
  imin   = 0,
  ig     = -1,
  irest  = 1,
  ntx    = 5,
  ntb    = 1,
  pres0  = 1.0,
  ntp    = 0,
  cut    = 10.0,
  ntr    = 0,
  ntc    = 2,
  ntf    = 2,
  nmropt = 1,
  ntxo   = 2,
  tempi  = 300.0,
  temp0  = 300.0,
  ntt    = 1,
  ioutfm = 1,
  nstlim = 20000000, dt = 0.002,
  ntpr = 25000, ntwx = 25000, ntwr = 50000, ntwv = -1,
 /
 
  
 &wt 
  type   = 'END'
 /
 
LISTOUT = POUT
DISANG = ../rst.dist
EOF
CUDA_VISIBLE_DEVICES=0 pmemd.cuda_SPFP -O -i Production.in -o Production_$i.out -p min.prmtop -c Production_$j.nrst -r Production_$i.nrst -x Production_$i.mdcrd
cd ..
done
