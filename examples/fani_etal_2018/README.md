# 2D Compressible Flow Example: Fani et al. PoF. (2018)
This file shows an example `ff-bifbox` workflow for reproducing the results of the paper:
```
@article{fani_etal_2018,
    author = {Fani, A. and Citro, V. and Giannetti, F. and Auteri, F.},
    title = "{Computation of the bluff-body sound generation by a self-consistent mean flow formulation}",
    journal = {Physics of Fluids},
    volume = {30},
    number = {3},
    year = {2018},
    doi = {10.1063/1.4997536},
}
```
The commands below illustrate how to analyze a 2D compressible flow around a cylinder using `ff-bifbox`.

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory for easy reference.
```
export workdir=examples/fani_etal_2018
```
3. Create symbolic links for governing equations and solver settings.
```
ln -sf $workdir/eqns_fani_etal_2018.idp eqns.idp
ln -sf $workdir/settings_fani_etal_2018.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from .geo files
```
FreeFem++-mpi -v 0 importgmsh.edp -dir $workdir -mi cylinder.geo
```
Note: since no `-mo` argument is specified, the output files (.msh) inherit the names of their parents (.geo).
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```
FreeFem++-mpi -v 0 $workdir/cylinder.edp -mo $workdir/cylinder
```

## Perform parallel computations using `ff-bifbox`
The number of processors is set using the `-n` argument from `mpirun`. Here, this value is set to 4.
### Zeroth order
1. Compute base state on the created mesh at Re = 10 from default guess
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -mi cylinder.msh -fo cylinder -1/Re 0.1 -1/Pr 1.38888888889 -Ma^2 0.04 -gamma 1.4
```

2. Continue base state along the parameter 1/Re with adaptive remeshing
```
mpirun -n 4 FreeFem++-mpi -v 0 basecontinue.edp -dir $workdir -fi cylinder.base -fo cylinder -param 1/Re -h0 -1 -scount 2 -maxcount 14 -mo cylinder -thetamax 5
```

3. Compute base states at Re = 50 and Re = 150 with guesses from continuation
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -fi cylinder_8.base -fo cylinder50 -1/Re 0.02
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -fi cylinder_14.base -fo cylinder150 -1/Re 0.0066666666667
```

4. Adapt mesh to the Re = 150 solution with a maximum triangle size restriction
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -fi cylinder150.base -fo cylinder150 -mo cylinder150 -thetamax 5 -hmax 5 -pv 1
```

### First order
1. Compute leading direct eigenmode at Re = 50 and Re = 150
```
mpirun -n 4 FreeFem++-mpi -v 0 modecompute.edp -dir $workdir -fi cylinder50.base -fo cylinder50 -so "" -eps_target 0.1+0.8i -sym 1
mpirun -n 4 FreeFem++-mpi -v 0 modecompute.edp -dir $workdir -fi cylinder150.base -fo cylinder150 -so "" -eps_target 0.2+0.8i -sym 1 -pv 1
```
NOTE: Here, the `-sym` argument specifies the asymmetric (1) or symmetric (0) reflective symmetry across the boundary `BCaxis`.

2. Compute the critical point and critical base/direct/adjoint solution
```
mpirun -n 4 FreeFem++-mpi -v 0 hopfcompute.edp -dir $workdir -fi cylinder50_0.mode -fo cylinder -param 1/Re
```

3. Adapt the mesh to the critical solution, save .vtu files for Paraview
```
mpirun -n 4 FreeFem++-mpi -v 0 hopfcompute.edp -dir $workdir -fi cylinder.hopf -fo cylinder -mo cylinderhopf -adaptto bda -param 1/Re -thetamax 5 -pv 1
```

4. Continue the neutral Hopf curve in the (1/Re,Ma^2)-plane with adaptive remeshing
```
mpirun -n 4 FreeFem++-mpi -v 0 hopfcontinue.edp -dir $workdir -fi cylinder.hopf -fo cylinder -mo cylinderhopf -adaptto bda -thetamax 5 -param1 Ma^2 -param2 1/Re -h0 -1 -scount 3 -maxcount 12
```

### Second order
- Compute 2nd-order weakly-nonlinear analysis, save .vtu files for Paraview
```
mpirun -n 4 FreeFem++-mpi -v 0 wnl2compute.edp -dir $workdir -fi cylinder.hopf -fo cylinder -pv 1
mpirun -n 4 FreeFem++-mpi -v 0 wnl2compute.edp -dir $workdir -fi cylinder_12.hopf -fo cylinder_12 -pv 1
```
NOTE: the signs and normalizations used in `wnl2compute.edp` are different than those of the Stuart-Landau coefficients in Sipp and Lebedev JFM (2007).
