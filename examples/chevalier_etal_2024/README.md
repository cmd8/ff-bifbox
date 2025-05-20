# Turbulent Swirling Jet Example: Chevalier etal, TCFD, (2024)
This file shows an example `ff-bifbox` workflow for reproducing the results of the study:
```
@article{chevalier_etal_2024,
  title={Resolvent analysis of a swirling turbulent jet},
  volume={38},
  DOI={10.1007/s00162-024-00704-2},
  journal={Theoretical and Computational Fluid Dynamics},
  publisher={Springer},
  author={Chevalier, Quentin and Douglas, Christopher M. and Lesshafft, Lutz},
  year={2024}
  pages={641-663}
}
```
The commands below illustrate how to perform a mean flow resolvent analysis of an incompressible swirling jet using `ff-bifbox`. The original codes used for the paper can be found on Quentin Chevalier's repository at [github.com/hawkspar](https://github.com/hawkspar).

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory and number of processors for easy reference.
```
export workdir=examples/chevalier_etal_2024/data
export nproc=4
```
3. Create symbolic links for solver settings.
```
ln -sf examples/chevalier_etal_2024/settings_chevalier_etal_2024.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### Build initial mesh directly from .geo files using Gmsh
```
FreeFem++-mpi -v 0 importgmsh.edp -gmshdir examples/chevalier_etal_2024 -dir $workdir -mi nozzle_lg.geo
FreeFem++-mpi -v 0 importgmsh.edp -gmshdir examples/chevalier_etal_2024 -dir $workdir -mi nozzle_sm.geo
```
Note: since no `-mo` argument is specified, the output files (.msh) inherit the names of their parents (.geo).

## Perform parallel computations using `ff-bifbox`
### Steady axisymmetric dynamics

0. Select base flow equations to model turbulent eddy viscosity using the Spalart-Allmaras turbulence model
```
ln -sf examples/chevalier_etal_2024/eqns_chevalier_etal_2024_baseflow.idp eqns.idp
```

1. Compute base state on the large mesh at $Re=10$, $S=0$ from default guess
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi nozzle_lg.msh -fo jet -1/Re 0.1 -S 0 -pv 1
```

2. Adapt base state to a coarser mesh for continuation
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi jet.base -fo jet_adapt_0 -mo nozzle_adapt_0 -thetamax 0.01 -pv 1
```

3. Continue base state along the parameter $1/Re$. NOTE: This problem becomes very poorly scaled at high $Re$, meaning numerical issues may arise and require creative workarounds.
```
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi jet_adapt_0.base -fo jet_adapt -param 1/Re -h0 -1 -scount 4 -maxcount 100 -mo nozzleRe_adapt -pv 1 -err 0.1 -anisomax 3 -thetamax 0.01 -snes_max_it 50 -hmin 1e-5
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi jet_adapt_100.base -fo jet_adapt_101 -mi nozzle_lg.msh -pv 1 -1/Re 5.0e-5
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi jet_adapt_101.base -fo jet_adapt_102 -mi nozzle_lg.msh -pv 1 -1/Re 3.0e-5
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi jet_adapt_102.base -fo jet_adapt_103 -mi nozzle_lg.msh -pv 1 -1/Re 1.0e-5
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi jet_adapt_103.base -fo jet_adapt_104 -mi nozzle_lg.msh -pv 1 -1/Re 8.0e-6
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi jet_adapt_104.base -fo jet_adapt_105 -mi nozzle_lg.msh -pv 1 -1/Re 6.0e-6
```

4. Compute the $Re=200,000$, $S=0$ case on the reference mesh
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi jet_adapt_105.base -fo S0p0Re200000jet -mi nozzle_lg.msh -pv 1 -1/Re 5.0e-6
```

5. Continue base state along the parameter $S$ using zeroth-order continuation
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi S0p0Re200000jet.base -fo S0p1Re200000jet -pv 1 -S 0.1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi S0p1Re200000jet.base -fo S0p2Re200000jet -pv 1 -S 0.2
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi S0p2Re200000jet.base -fo S0p3Re200000jet -pv 1 -S 0.3
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi S0p3Re200000jet.base -fo S0p4Re200000jet -pv 1 -S 0.4
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi S0p4Re200000jet.base -fo S0p5Re200000jet -pv 1 -S 0.5
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi S0p5Re200000jet.base -fo S0p6Re200000jet -pv 1 -S 0.6
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi S0p6Re200000jet.base -fo S0p7Re200000jet -pv 1 -S 0.7
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi S0p7Re200000jet.base -fo S0p8Re200000jet -pv 1 -S 0.8
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi S0p8Re200000jet.base -fo S0p9Re200000jet -pv 1 -S 0.9
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi S0p9Re200000jet.base -fo S1p0Re200000jet -pv 1 -S 1.0
```

### Perturbation dynamics

0. Select perturbation equations to use a frozen eddy viscosity model
```
ln -sf examples/chevalier_etal_2024/eqns_chevalier_etal_2024_perturbations.idp eqns.idp
```

1. Compute eigenvalue spectrum of the $Re=200,000$, $S=1$ flow on the smaller mesh for different azimuthal wavenumbers (to confirm that the flow is globally stable).
```
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi S1p0Re200000jet.base -so S1p0Re200000 -eps_target 0.1+0.25i -ntarget 13 -targetf 0.1+6.25i -sym 0 -eps_nev 20 -eps_pos_gen_non_hermitian -mi nozzle_sm.msh
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi S1p0Re200000jet.base -so S1p0Re200000 -eps_target 0.1-6.25i -ntarget 26 -targetf 0.1+6.25i -sym -1 -eps_nev 20 -eps_pos_gen_non_hermitian -mi nozzle_sm.msh
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi S1p0Re200000jet.base -so S1p0Re200000 -eps_target 0.1-6.25i -ntarget 26 -targetf 0.1+6.25i -sym -2 -eps_nev 20 -eps_pos_gen_non_hermitian -mi nozzle_sm.msh
```

2. Compute dominant resolvent gain of the $Re=200,000$, $S=1$ flow on the smaller mesh for different azimuthal wavenumbers. NOTE: Here, forcing is NOT restricted to a set portion of the mesh as it is in the paper, which may lead to numerical artifacts at low frequencies due to spurious variations in the outer coflow surrounding the jet.
```
ff-mpirun -np $nproc rslvcompute.edp -v 0 -dir $workdir -fi S1p0Re200000jet.base -so S1p0Re200000 -omega 0 -nomega 64 -omegaf 6.3 -sym 0 -eps_nev 1 -strict 1 -mi nozzle_sm.msh
ff-mpirun -np $nproc rslvcompute.edp -v 0 -dir $workdir -fi S1p0Re200000jet.base -so S1p0Re200000 -omega -6.3 -nomega 127 -omegaf 6.3 -sym -1 -eps_nev 1 -strict 1 -mi nozzle_sm.msh
ff-mpirun -np $nproc rslvcompute.edp -v 0 -dir $workdir -fi S1p0Re200000jet.base -so S1p0Re200000 -omega -6.3 -nomega 127 -omegaf 6.3 -sym -2 -eps_nev 1 -strict 1 -mi nozzle_sm.msh
```

3. Compute dominant resolvent forcing and response modes for $Re=200,000$, $S=1$, $St=0.004$, and $m=\pm2$ as in the paper in Figs 8,9,10. NOTE: $\omega=2\pi{}St$, and, due to the SO(2) symmetry, (S,m,St)=(S,-m,-St). Again, forcing is NOT restricted to the jet region, which can lead to significant differences due to spurious variations in the outer coflow surrounding the jet.
```
ff-mpirun -np $nproc rslvcompute.edp -v 0 -dir $workdir -fi S1p0Re200000jet.base -mo S1p0Re200000St0p004 -omega -0.02513274 -nomega 2 -omegaf 0.02513274 -sym -2 -eps_nev 1 -strict 1 -mi nozzle_sm.msh -pv 1
```