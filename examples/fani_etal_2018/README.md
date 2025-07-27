# 2D Compressible Flow Example: Fani et al. PoF. (2018)
This file shows an example `ff-bifbox` workflow for reproducing the results of the paper:
```tex
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
```sh
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory and number of processors for easy reference.
```sh
export workdir=examples/fani_etal_2018/data
export nproc=4
```
3. Create symbolic links for governing equations and solver settings.
```sh
ln -sf examples/fani_etal_2018/eqns_fani_etal_2018.idp eqns.idp
ln -sf examples/fani_etal_2018/settings_fani_etal_2018.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from `.geo` files
```sh
FreeFem++-mpi -v 0 importgmsh.edp -gmshdir examples/fani_etal_2018 -dir $workdir -mi cylinder.geo
```
Note: since no `-mo` argument is specified, the output files (`.msh`) inherit the names of their parents (`.geo`).
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```sh
FreeFem++-mpi -v 0 examples/fani_etal_2018/cylinder.edp -mo $workdir/cylinder
```

## Perform parallel computations using `ff-bifbox`
### Zeroth order
1. Compute base state on the created mesh at $Re=10$ from default guess
```sh
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi cylinder.msh -fo cylinder -1/Re 0.1 -1/Pr 1.38888888889 -Ma^2 0.04 -gamma 1.4
```

2. Continue base state along the parameter $1/Re$ with adaptive remeshing
```sh
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi cylinder.base -fo cylinder -param 1/Re -h0 -1 -scount 2 -maxcount 14 -mo cylinder -thetamax 5
```

3. Compute base states at $Re\sim50$ and $Re=150$ with guesses from continuation
```sh
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi cylinder_8.base -fo cylinder50 -1/Re 0.021
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi cylinder_14.base -fo cylinder150 -1/Re 0.0066666666667
```

4. Adapt mesh to the $Re=150$ solution with a maximum triangle size restriction
```sh
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi cylinder150.base -fo cylinder150 -mo cylinder150 -thetamax 5 -hmax 5 -pv 1
```

### First order
1. Compute leading direct eigenmode at $Re\sim50$ and $Re=150$
```sh
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi cylinder50.base -fo cylinder50 -eps_target 0.1+0.7i -sym 1 -eps_pos_gen_non_hermitian
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi cylinder150.base -fo cylinder150 -eps_target 0.2+0.8i -sym 1 -pv 1 -eps_pos_gen_non_hermitian
```
NOTE: Here, the `-sym` argument specifies the asymmetric (1) or symmetric (0) reflective symmetry across the boundary `BCaxis`.

2. Compute the critical point and critical base/direct/adjoint solution
```sh
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi cylinder50.mode -fo cylinder -param 1/Re -nf 0
```

3. Adapt the mesh to the critical solution, save `.vtu` files for Paraview
```sh
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi cylinder.hopf -fo cylinder -mo cylinderhopf -adaptto bda -param 1/Re -thetamax 5 -pv 1
```

4. Continue the neutral Hopf curve in the $(1/Re,Ma^2)$-plane with adaptive remeshing
```sh
ff-mpirun -np $nproc hopfcontinue.edp -v 0 -dir $workdir -fi cylinder.hopf -fo cylinder -mo cylinderhopf -adaptto bda -thetamax 5 -param Ma^2 -param2 1/Re -h0 -1 -scount 3 -maxcount 12
```
NOTE: the signs and normalizations of the normal form coefficients used in `hopfcompute.edp` are different than those of the Stuart-Landau coefficients in [Sipp and Lebedev JFM (2007)](../sipp_lebedev_2007/).

5. Continue the branch of periodic solutions emanating from the Hopf point along $1/Re$ using harmonic balance.
```sh
ff-mpirun -np $nproc porbcontinue.edp -v 0 -dir $workdir -fi cylinder.hopf -fo cylinder -mo cylinderporb -adaptto 01 -thetamax 5 -param 1/Re -h0 -1 -scount 5 -maxcount -1 -paramtarget 0.00666667
```
NOTE: the formulation in `ff-bifbox` is fully self-consistent, and does not neglect the unsteady nonlinear interactions as in the original paper. 