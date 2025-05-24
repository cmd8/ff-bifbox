# 2D Incompressible Swirling Flow Example: Douglas, TCFD, (2024)
This file shows an example `ff-bifbox` workflow for reproducing the results in section III.B of the study:
```
@article{douglas_2024,
  title={A Balanced Outflow Boundary Condition for Swirling Flows},
  journal={Theoretical and Computational Fluid Dynamics},
  publisher={Springer Nature},
  author={Douglas, Christopher M.},
  year={2024},
  DOI={10.1007/s00162-024-00701-5},
}
```
The commands below illustrate how to perform the analysis of the Grabowski--Berger vortex as in the paper using `ff-bifbox`. Note: a reproducer for the portion of the analysis focused on the rotating pipe flow is given in the Supplementary Materials.

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory and number of processors for easy reference.
```
export workdir=examples/douglas_2024/data
export nproc=4
```
3. Create symbolic links for governing equations and solver settings.
```
ln -sf examples/douglas_2024/eqns_meliga_etal_2012.idp eqns.idp
ln -sf examples/douglas_2024/settings_meliga_etal_2012.idp settings.idp
```
OR
```
ln -sf examples/douglas_2024/eqns_douglas_2024_convect.idp eqns.idp
ln -sf examples/douglas_2024/settings_douglas_2024_convect.idp settings.idp
```
OR
```
ln -sf examples/douglas_2024/eqns_douglas_2024_balanced.idp eqns.idp
ln -sf examples/douglas_2024/settings_douglas_2024_balanced.idp settings.idp
```
OR
```
ln -sf examples/douglas_2024/eqns_douglas_2024_modified.idp eqns.idp
ln -sf examples/douglas_2024/settings_douglas_2024_modified.idp settings.idp
```
OR
```
ln -sf examples/douglas_2024/eqns_douglas_2024_freeout.idp eqns.idp
ln -sf examples/douglas_2024/settings_douglas_2024_freeout.idp settings.idp
```
OR
```
ln -sf examples/douglas_2024/eqns_douglas_2024_zerotract.idp eqns.idp
ln -sf examples/douglas_2024/settings_douglas_2024_zerotract.idp settings.idp
```

## Build initial meshes
Note: this example does not make use of adaptive meshing.
```
FreeFem++-mpi -v 0 examples/douglas_2024/grabowski.edp -mo $workdir/G
```
## Run the standalone serial FreeFEM code provided in the Supplementary Materials
```
FreeFem++ -v 0 examples/douglas_2024/example1_suppmat.edp
```

## Perform parallel computations for Grabowski--Berger vortex flow using `ff-bifbox`
### Steady axisymmetric dynamics
1. Compute reference base states on the largest mesh at $Re=200$, $S=0.85$ to $S=1.3$ from default guess.
```
ln -sf examples/douglas_2024/eqns_meliga_etal_2012.idp eqns.idp
ln -sf examples/douglas_2024/settings_meliga_etal_2012.idp settings.idp
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi G3.msh -fo meligaS0p85 -Re 200 -S 0.85 -snes_rtol 0
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi meligaS0p85.base -fo meligaS0p9 -S 0.9 -snes_rtol 0
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi meligaS0p9.base -fo meligaS1 -S 1.0 -snes_rtol 0
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi meligaS1.base -fo meligaS1p095 -S 1.095 -snes_rtol 0
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi meligaS1p095.base -fo meligaS1p3 -S 1.3 -snes_rtol 0
```

2. Compute base states with convective BC on the truncated mesh.
```
ln -sf examples/douglas_2024/eqns_douglas_2024_convect.idp eqns.idp
ln -sf examples/douglas_2024/settings_douglas_2024_convect.idp settings.idp
ff-mpirun -np $nproc examples/douglas_2024/basecomputeaug.edp -v 0 -dir $workdir -mi G2.msh -fi meligaS0p85.base -fo convectS0p85 -C 1 -snes_rtol 0 -pv 1
FreeFem++-mpi -v 0 examples/douglas_2024/computebaseerror.edp -fi convect -ci S0p85 -fo convectS0p85err -dir $workdir -pv 1
ff-mpirun -np $nproc examples/douglas_2024/basecomputeaug.edp -v 0 -dir $workdir -mi G2.msh -fi meligaS0p9.base -fo convectS0p9 -C 1 -snes_rtol 0
ff-mpirun -np $nproc examples/douglas_2024/basecomputeaug.edp -v 0 -dir $workdir -mi G2.msh -fi meligaS1.base -fo convectS1 -C 1 -snes_rtol 0 -pv 1
FreeFem++-mpi -v 0 examples/douglas_2024/computebaseerror.edp -fi convect -ci S1 -fo convectS1err -dir $workdir -pv 1
ff-mpirun -np $nproc examples/douglas_2024/basecomputeaug.edp -v 0 -dir $workdir -mi G2.msh -fi meligaS1p095.base -fo convectS1p095 -C 1 -snes_rtol 0
ff-mpirun -np $nproc examples/douglas_2024/basecomputeaug.edp -v 0 -dir $workdir -mi G2.msh -fi meligaS1p3.base -fo convectS1p3 -C 1 -snes_rtol 0
```

3. Compute base states with balanced outflow BC on the truncated mesh.
```
ln -sf examples/douglas_2024/eqns_douglas_2024_balanced.idp eqns.idp
ln -sf examples/douglas_2024/settings_douglas_2024_balanced.idp settings.idp
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi G2.msh -fo balancedS0p85 -Re 200 -S 0.85 -snes_rtol 0 -pv 1
FreeFem++-mpi -v 0 examples/douglas_2024/computebaseerror.edp -fi balanced -ci S0p85 -fo balancedS0p85err -dir $workdir -pv 1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi balancedS0p85.base -fo balancedS0p9 -S 0.9 -snes_rtol 0
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi balancedS0p9.base -fo balancedS1 -S 1 -snes_rtol 0 -pv 1
FreeFem++-mpi -v 0 examples/douglas_2024/computebaseerror.edp -fi balanced -ci S1 -fo balancedS1err -dir $workdir -pv 1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi balancedS1.base -fo balancedS1p095 -S 1.095 -snes_rtol 0
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi balancedS1p095.base -fo balancedS1p3 -S 1.3 -snes_rtol 0
```

4. Compute base states with free outflow BC on the truncated mesh.
```
ln -sf examples/douglas_2024/eqns_douglas_2024_freeout.idp eqns.idp
ln -sf examples/douglas_2024/settings_douglas_2024_freeout.idp settings.idp
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi G2.msh -fo freeoutS0p5 -Re 200 -S 0.5 -snes_rtol 0
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi freeoutS0p5.base -fo freeout -param S -h0 10 -paramtarget 0.85 -maxcount -1 -scount 25
# replace `freeout_125.base` with `freeout_XXX.base` where `XX` is the last index of the continuation.
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi freeout_125.base -fo freeoutS0p85 -S 0.85 -snes_rtol 0 -pv 1
FreeFem++-mpi -v 0 examples/douglas_2024/computebaseerror.edp -fi freeout -ci S0p85 -fo freeoutS0p85err -dir $workdir -pv 1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi freeoutS0p85.base -fo freeoutS0p9 -S 0.9 -snes_rtol 0
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi freeoutS0p9.base -fo freeoutS1 -S 1 -snes_rtol 0 -pv 1
FreeFem++-mpi -v 0 examples/douglas_2024/computebaseerror.edp -fi freeout -ci S1 -fo freeoutS1err -dir $workdir -pv 1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi freeoutS1.base -fo freeoutS1p095 -S 1.095 -snes_rtol 0
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi freeoutS1p095.base -fo freeoutS1p2 -S 1.2 -snes_rtol 0
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi freeoutS1p2.base -fo freeoutS1p3 -S 1.3 -snes_rtol 0
```

### Linear 3-D dynamics
1. Compute reference eigenvalues/eigenmodes on the largest mesh at $Re=200$, $S=1$ and $S=1.3$.
```
ln -sf examples/douglas_2024/eqns_meliga_etal_2012.idp eqns.idp
ln -sf examples/douglas_2024/settings_meliga_etal_2012.idp settings.idp
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi meligaS1.base -fo meligaS1m1 -sym -1 -eps_pos_gen_non_hermitian -eps_target 0.1+1.2i -eps_nev 1
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi meligaS1.base -fo meligaS1m1adj -sym -1 -eps_target 0.1-1.2i -eps_nev 1 -adj 1
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi meligaS1p3.base -fo meligaS1p3m2 -sym -2 -eps_pos_gen_non_hermitian -eps_target 0.1+2.5i -eps_nev 1
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi meligaS1p3.base -fo meligaS1p3m2adj -sym -2 -eps_target 0.1-2.5i -eps_nev 1 -adj 1
```

2. Compute eigenmodes with convective BC on the truncated mesh.
```
ln -sf examples/douglas_2024/eqns_douglas_2024_convect.idp eqns.idp
ln -sf examples/douglas_2024/settings_douglas_2024_convect.idp settings.idp
ff-mpirun -np $nproc examples/douglas_2024/modecomputeaug.edp -v 0 -dir $workdir -mi G2.msh -fi meligaS1.base -fo convectS1m1 -C 0.6 -Cr 0.1 -sym -1 -eps_pos_gen_non_hermitian -eps_target 0.1+1.2i -eps_nev 1
FreeFem++-mpi -v 0 examples/douglas_2024/computemodeerror.edp -C 0.6 -Cr 0.1 -fi convect -ci S1m1 -fo convectS1m1err -dir $workdir -pv 1
ff-mpirun -np $nproc examples/douglas_2024/modecomputeaug.edp -v 0 -dir $workdir -mi G2.msh -fi meligaS1p3.base -fo convectS1p3m2 -C 0.6 -Cr 0.1 -sym -2 -eps_pos_gen_non_hermitian -eps_target 0.1+2.5i -eps_nev 1
FreeFem++-mpi -v 0 examples/douglas_2024/computemodeerror.edp -C 0.6 -Cr 0.1 -fi convect -ci S1p3m2 -fo convectS1p3m2err -dir $workdir -pv 1
```

3. Compute eigemodes with balanced BC on the truncated mesh.
```
ln -sf examples/douglas_2024/eqns_douglas_2024_balanced.idp eqns.idp
ln -sf examples/douglas_2024/settings_douglas_2024_balanced.idp settings.idp
FreeFem++-mpi -v 0 examples/douglas_2024/basefieldappend.edp -fi meligaS1.base -fo meligaappendS1 -dir $workdir
FreeFem++-mpi -v 0 examples/douglas_2024/modefieldappend.edp -fi meligaS1m1.mode -fo meligaappendS1m1 -dir $workdir
FreeFem++-mpi -v 0 examples/douglas_2024/modefieldappend.edp -fi meligaS1m1adj.mode -fo meligaappendS1m1adj -dir $workdir
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -mi G2.msh -fi meligaappendS1.base -fo balancedS1m1 -sym -1 -eps_target 0.1+1.2i -eps_nev 1
FreeFem++-mpi -v 0 examples/douglas_2024/computemodeerror.edp -ri meligaappend -fi balanced -ci S1m1 -fo balancedS1m1err -dir $workdir -pv 1
FreeFem++-mpi -v 0 examples/douglas_2024/basefieldappend.edp -fi meligaS1p3.base -fo meligaappendS1p3 -dir $workdir
FreeFem++-mpi -v 0 examples/douglas_2024/modefieldappend.edp -fi meligaS1p3m2.mode -fo meligaappendS1p3m2 -dir $workdir
FreeFem++-mpi -v 0 examples/douglas_2024/modefieldappend.edp -fi meligaS1p3m2adj.mode -fo meligaappendS1p3m2adj -dir $workdir
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -mi G2.msh -fi meligaappendS1p3.base -fo balancedS1p3m2 -sym -2 -eps_target 0.1+2.5i -eps_nev 1
FreeFem++-mpi -v 0 examples/douglas_2024/computemodeerror.edp -ri meligaappend -fi balanced -ci S1p3m2 -fo balancedS1p3m2err -dir $workdir -pv 1
```

4. Compute eigenmodes with free outflow BC on the truncated mesh.
```
ln -sf examples/douglas_2024/eqns_douglas_2024_freeout.idp eqns.idp
ln -sf examples/douglas_2024/settings_douglas_2024_freeout.idp settings.idp
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -mi G2.msh -fi meligaS1.base -fo freeoutS1m1 -sym -1 -eps_pos_gen_non_hermitian -eps_target 0.1+1.2i -eps_nev 1
FreeFem++-mpi -v 0 examples/douglas_2024/computemodeerror.edp -fi freeout -ci S1m1 -fo freeoutS1m1err -dir $workdir -pv 1
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -mi G2.msh -fi meligaS1p3.base -fo freeoutS1p3m2 -sym -2 -eps_pos_gen_non_hermitian -eps_target 0.1+2.5i -eps_nev 1
FreeFem++-mpi -v 0 examples/douglas_2024/computemodeerror.edp -fi freeout -ci S1p3m2 -fo freeoutS1p3m2err -dir $workdir -pv 1
```

5. Compute eigemodes with modified BC on the truncated mesh.
```
ln -sf examples/douglas_2024/eqns_douglas_2024_modified.idp eqns.idp
ln -sf examples/douglas_2024/settings_douglas_2024_modified.idp settings.idp
FreeFem++-mpi -v 0 examples/douglas_2024/basefieldappend.edp -fi meligaS1.base -fo meligaappend2S1 -dir $workdir
FreeFem++-mpi -v 0 examples/douglas_2024/modefieldappend.edp -fi meligaS1m1.mode -fo meligaappend2S1m1 -dir $workdir
FreeFem++-mpi -v 0 examples/douglas_2024/modefieldappend.edp -fi meligaS1m1adj.mode -fo meligaappend2S1m1adj -dir $workdir
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -mi G2.msh -fi meligaappend2S1.base -fo modifiedS1m1 -sym -1 -eps_target 0.1+1.2i -eps_nev 1
FreeFem++-mpi -v 0 examples/douglas_2024/computemodeerror.edp -ri meligaappend2 -fi modified -ci S1m1 -fo modifiedS1m1err -dir $workdir -pv 1
FreeFem++-mpi -v 0 examples/douglas_2024/basefieldappend.edp -fi meligaS1p3.base -fo meligaappend2S1p3 -dir $workdir
FreeFem++-mpi -v 0 examples/douglas_2024/modefieldappend.edp -fi meligaS1p3m2.mode -fo meligaappend2S1p3m2 -dir $workdir
FreeFem++-mpi -v 0 examples/douglas_2024/modefieldappend.edp -fi meligaS1p3m2adj.mode -fo meligaappend2S1p3m2adj -dir $workdir
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -mi G2.msh -fi meligaappend2S1p3.base -fo modifiedS1p3m2 -sym -2 -eps_target 0.1+2.5i -eps_nev 1
FreeFem++-mpi -v 0 examples/douglas_2024/computemodeerror.edp -ri meligaappend2 -fi modified -ci S1p3m2 -fo modifiedS1p3m2err -dir $workdir -pv 1
```