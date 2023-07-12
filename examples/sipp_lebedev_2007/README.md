# 2D Incompressible Flow Example: Sipp and Lebedev. JFM. (2007)
This file shows an example `ff-bifbox` workflow for reproducing the results of the paper:
```
@article{sipp_lebedev_2007,
  title={Global stability of base and mean flows: a general approach and its applications to cylinder and open cavity flows},
  volume={593},
  DOI={10.1017/S0022112007008907},
  journal={Journal of Fluid Mechanics},
  publisher={Cambridge University Press},
  author={Sipp, Denis and Lebedev, Anton},
  year={2007},
  pages={333–358}
}
```
The commands below illustrate how to perform a weakly nonlinear analysis of the 2D incompressible flow around a cylinder and an open cavity using `ff-bifbox`.

Note that, in this example of Sipp and Lebedev, viscosity is parameterized by 1/Re instead of Re in order to make the equation system linear with respect to the control parameter. Though such scalings do improve the performance of predictor-corrector methods and weakly-nonlinear analysis, `ff-bifbox` does not require the system to be linear in the parameters.

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory for easy reference.
```
export workdir=examples/sipp_lebedev_2007
```
3. Create symbolic links for governing equations and solver settings.
```
ln -sf $workdir/eqns_sipp_lebedev_2007.idp eqns.idp
ln -sf $workdir/settings_sipp_lebedev_2007.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from .geo files
```
FreeFem++-mpi -v 0 importgmsh.edp -dir $workdir -mi cylinder.geo
FreeFem++-mpi -v 0 importgmsh.edp -dir $workdir -mi cavity.geo
```
Note: since no `-mo` argument is specified, the output files (.msh) inherit the names of their parents (.geo).
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```
FreeFem++-mpi -v 0 $workdir/cylinder.edp -mo $workdir/cylinder
FreeFem++-mpi -v 0 $workdir/cavity.edp -mo $workdir/cavity
```

## Perform parallel computations using `ff-bifbox`
The number of processors is set using the `-n` argument from `mpirun`. Here, this value is set to 4.
### Zeroth order
1. Compute base states on the created meshes at Re = 10 from default guess
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -mi cylinder.msh -fo cylinder -1/Re 0.1
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -mi cavity.msh -fo cavity -1/Re 0.1
```

2. Continue base state along the parameter 1/Re with adaptive remeshing
```
mpirun -n 4 FreeFem++-mpi -v 0 basecontinue.edp -dir $workdir -fi cylinder.base -fo cylinder -param 1/Re -h0 -1 -scount 2 -maxcount 8 -mo cylinder -thetamax 5
mpirun -n 4 FreeFem++-mpi -v 0 basecontinue.edp -dir $workdir -fi cavity.base -fo cavity -param 1/Re -h0 -1 -scount 4 -maxcount 16 -mo cavity
```

3. Compute base states at Re = 50 (cylinder) and Re = 4000 (cavity) with guess from continuation
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -fi cylinder_8.base -fo cylinder50 -1/Re 0.021
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -fi cavity_16.base -fo cavity4000 -1/Re 0.00025
```

### First order
1. Compute leading direct eigenmode at Re = 50 (cylinder) and Re = 4000 (cavity)
```
mpirun -n 4 FreeFem++-mpi -v 0 modecompute.edp -dir $workdir -fi cylinder50.base -fo cylinder50 -so "" -eps_target 0.1+0.8i -sym 1
mpirun -n 4 FreeFem++-mpi -v 0 modecompute.edp -dir $workdir -fi cavity4000.base -fo cavity4000 -so "" -eps_target 0.1+8.0i -sym 0
```
NOTE: Here, the `-sym` argument specifies the asymmetric (1) or symmetric (0) reflective symmetry across the boundary `BCaxis`.

2. Compute the critical point and critical base/direct/adjoint solution
```
mpirun -n 4 FreeFem++-mpi -v 0 hopfcompute.edp -dir $workdir -fi cylinder50.mode -fo cylinder -param 1/Re -nf 0
mpirun -n 4 FreeFem++-mpi -v 0 hopfcompute.edp -dir $workdir -fi cavity4000.mode -fo cavity -param 1/Re -nf 0
```

3. Adapt the mesh to the critical solution, save .vtu files for Paraview
```
mpirun -n 4 FreeFem++-mpi -v 0 hopfcompute.edp -dir $workdir -fi cylinder.hopf -fo cylinder -mo cylinderhopf -adaptto bda -param 1/Re -thetamax 5 -pv 1
mpirun -n 4 FreeFem++-mpi -v 0 hopfcompute.edp -dir $workdir -fi cavity.hopf -fo cavity -mo cavityhopf -adaptto bda -param 1/Re -pv 1
```
NOTE: the normalizations for the direct and adjoint eigenmodes (and therefore also the weakly-nonlinear corrections) used by `ff-bifbox` are different than the normalizations used by Sipp and Lebedev. This causes the results to differ by a scaling factor. Further, the sign of the Stuart-Landau coefficients in Sipp and Lebedev JFM (2007) are opposite to those in the normal form used in `hopfcompute.edp`.
