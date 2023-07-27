# 2D Incompressible Swirling Flow Example: Meliga et al, JFM, (2012)
This file shows an example `ff-bifbox` workflow for reproducing the results in the study:
```
@article{meliga_etal_2012,
  title={A weakly nonlinear mechanism for mode selection in swirling jets},
  volume={699},
  DOI={10.1017/jfm.2012.93},
  journal={Journal of Fluid Mechanics},
  author={Meliga, Philippe and Gallaire, François and Chomaz, Jean-Marc},
  year={2012},
  pages={216–262}}
```
The commands below illustrate how to perform a bifurcation analysis of an incompressible swirling flow using `ff-bifbox`.

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory for easy reference.
```
export workdir=examples/meliga_etal_2012
```
3. Create symbolic links for governing equations and solver settings.
```
ln -sf $workdir/eqns_meliga_etal_2012.idp eqns.idp
ln -sf $workdir/settings_meliga_etal_2012.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from .geo files
```
FreeFem++-mpi -v 0 importgmsh.edp -dir $workdir -mi vortex.geo
```
Note: since no `-mo` argument is specified, the output files (.msh) inherit the names of their parents (.geo).
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```
FreeFem++-mpi -v 0 $workdir/vortex.edp -mo $workdir/vortex
```

## Perform parallel computations using `ff-bifbox`
The number of processors is set using the `-n` argument from `mpirun`. Here, this value is set to 4.
### Steady axisymmetric dynamics
1. Compute base states on the created mesh at Re = 200 from default guess
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -mi vortex.msh -fo vortex -1/Re 0.005 -S 0
```
2. Continue base state along the parameter S with adaptive remeshing
```
mpirun -n 4 FreeFem++-mpi -v 0 basecontinue.edp -dir $workdir -fi vortex.base -fo vortex -param S -h0 1 -scount 4 -maxcount 40 -mo vortexadapt
```

### Unsteady 3-D dynamics
1. Compute base state near the double Hopf point
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -mi vortex.msh -fo vortexDH -1/Re 0.0139 -S 1
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -fi vortexDH.base -fo vortexDH -S 1.44
```
2. Compute near-critical modes
```
mpirun -n 4 FreeFem++-mpi -v 0 modecompute.edp -dir $workdir -fo vortexm1 -fi vortexDH.base -sym -1 -eps_target 0+1i
mpirun -n 4 FreeFem++-mpi -v 0 modecompute.edp -dir $workdir -fo vortexm2 -fi vortexDH.base -sym -2 -eps_target 0+2i
```
3. Compute Hopf-Hopf point assuming non-resonant interaction
```
mpirun -n 4 FreeFem++-mpi -v 0 hohocompute.edp -dir $workdir -fo vortexDH -fi vortexm2.mode -fi2 vortexm1.mode -param S -param2 1/Re -nf 0
mpirun -n 4 FreeFem++-mpi -v 0 hohocompute.edp -dir $workdir -fo vortex -fi vortexDH.hoho -param S -param2 1/Re -adaptto bda -mo vortexm1m2adapt
```

4. Compute Hopf-Hopf point assuming 2:1 resonant interaction
```
mpirun -n 4 FreeFem++-mpi -v 0 hohocompute.edp -dir $workdir -fo vortexDH21res -fi vortexDH.hoho -param S -param2 1/Re -res1x 2
```
