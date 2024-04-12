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
2. Export working directory and number of processors for easy reference.
```
export workdir=examples/sipp_lebedev_2007/data
export nproc=4
```
3. Create symbolic links for governing equations and solver settings.
```
ln -sf examples/sipp_lebedev_2007/eqns_sipp_lebedev_2007.idp eqns.idp
ln -sf examples/sipp_lebedev_2007/settings_sipp_lebedev_2007.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from .geo files
```
FreeFem++-mpi -v 0 importgmsh.edp -gmshdir examples/sipp_lebedev_2007 -dir $workdir -mi cylinder.geo
FreeFem++-mpi -v 0 importgmsh.edp -gmshdir examples/sipp_lebedev_2007 -dir $workdir -mi cavity.geo
```
Note: since no `-mo` argument is specified, the output files (.msh) inherit the names of their parents (.geo).
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```
FreeFem++-mpi -v 0 examples/sipp_lebedev_2007/cylinder.edp -mo $workdir/cylinder
FreeFem++-mpi -v 0 examples/sipp_lebedev_2007/cavity.edp -mo $workdir/cavity
```

## Perform parallel computations using `ff-bifbox`
### Zeroth order
1. Compute base states on the created meshes at Re = 10 from default guess
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi cylinder.msh -fo cylinder -1/Re 0.1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi cavity.msh -fo cavity -1/Re 0.1
```

2. Continue base state along the parameter 1/Re with adaptive remeshing
```
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi cylinder.base -fo cylinder -param 1/Re -h0 -1 -scount 2 -maxcount 8 -mo cylinder -thetamax 5
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi cavity.base -fo cavity -param 1/Re -h0 -1 -scount 4 -maxcount 16 -mo cavity
```

3. Compute base states at Re = 50 (cylinder) and Re = 4000 (cavity) with guess from continuation
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi cylinder_8.base -fo cylinder50 -1/Re 0.021
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi cavity_16.base -fo cavity4000 -1/Re 0.00025
```

### First & second order
1. Compute leading direct eigenmode at Re = 50 (cylinder) and Re = 4000 (cavity)
```
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi cylinder50.base -fo cylinder50 -eps_target 0.1+0.8i -sym 1 -eps_pos_gen_non_hermitian
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi cavity4000.base -fo cavity4000 -eps_target 0.1+8.0i -sym 0 -eps_pos_gen_non_hermitian
```
NOTE: Here, the `-sym` argument specifies the asymmetric (1) or symmetric (0) reflective symmetry across the boundary `BCaxis`.

2. Compute the critical point and critical base/direct/adjoint solution
```
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi cylinder50.mode -fo cylinder -param 1/Re -nf 0
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi cavity4000.mode -fo cavity -param 1/Re -nf 0
```

3. Adapt the mesh to the critical solution, save .vtu files for Paraview
```
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi cylinder.hopf -fo cylinderadapt -mo cylinderhopf -adaptto bda -param 1/Re -thetamax 5 -pv 1 -wnl 1 
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi cavity.hopf -fo cavityadapt -mo cavityhopf -adaptto bda -param 1/Re -pv 1 -wnl 1
```
NOTE: the normalizations for the direct and adjoint eigenmodes (and therefore also the weakly-nonlinear corrections) used by `ff-bifbox` are different than the normalizations used by Sipp and Lebedev. This causes the results to differ by a complex scaling factor. Further, the sign of the Stuart-Landau coefficients in Sipp and Lebedev JFM (2007) are opposite to those of the normal form used in `hopfcompute.edp`.


### Harmonic Balance
1. Continue periodic orbit from initial Hopf bifurcations using 2nd-order Harmonic Balance (Caution: memory intensive!)
```
ff-mpirun -np $nproc porbcontinue.edp -v 0 -dir $workdir -fi cylinder.hopf -fo cylinderNh2 -Nh 2 -mo cylinderporb -param 1/Re -thetamax 5 -h0 -1 -scount 5 -maxcount 10
ff-mpirun -np $nproc porbcontinue.edp -v 0 -dir $workdir -fi cavity.hopf -fo cavityNh2 -Nh 2 -mo cavityporb -param 1/Re -h0 -1 -scount 4 -maxcount 8
```

2. Compute periodic orbits at Re = 50 (cylinder) and Re = 5000 (cavity) using 3rd-order Harmonic Balance with block Jacobi solver (Caution: memory intensive!)
```
ff-mpirun -np $nproc porbcompute.edp -v 0 -dir $workdir -fi cylinderNh2_10.porb -fo cylinder50Nh3 -Nh 3 -1/Re 0.02 -blocks 3
ff-mpirun -np $nproc porbcompute.edp -v 0 -dir $workdir -fi cavityNh2_8.porb -fo cavity5000Nh3 -Nh 3 -1/Re 0.0002 -blocks 3
```
NOTE: Sipp & Lebedev do not perform harmonic balance analysis. See Fabre et al., Appl. Mech. Rev. 2018 and Meliga, JFM, 2017 for reference results from the cylinder and cavity geometries, respectively.