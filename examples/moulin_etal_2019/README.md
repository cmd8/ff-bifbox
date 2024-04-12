# 3D Incompressible Wake Flow Example: Moulin et al., (2019)
This file shows an example `ff-bifbox` workflow for reproducing the results of the study:
```
@article{moulin_etal_2019,
    Author = {Moulin, Johann and Jolivet, Pierre and Marquet, Olivier},
    Title = {{Augmented Lagrangian Preconditioner for Large-Scale Hydrodynamic Stability Analysis}},
    Year = {2019},
    Volume = {351},
    Pages = {718--743},
    DOI = {10.1016/j.cma.2019.03.052},
    Journal = {Computer Methods in Applied Mechanics and Engineering},
    Publisher = {Elsevier},
    Url = {https://github.com/prj-/moulin2019al}
}
```
The commands below illustrate how to run the perform a stability analysis of 3D wake behind a rectangular plate using `ff-bifbox` with the mAL preconditioner implemented in this study. Note that since this study leverages iterative methods, attempts to solve for bifurcation points (fold, hopf, etc.) WILL NOT WORK since the matrix is horribly ill-conditioned near such singularities. This method should only be used for base flow calculations, stability analysis, resolvent analysis, and/or time-domain simulations. (The latter of which could be done faster with other preconditioning strategies.)

IMPORTANT NOTE: The ability to solve 3 dimensional problems in ff-bifbox is still under development! In particular, 3D mesh adaptation with `mmg3d` may contain bugs. 

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```

2. Export working directory and number of processors for easy reference.
```
export workdir=examples/moulin_etal_2019/data
export nproc=4
```

3. Create symbolic links for governing equations and solver settings.
```
ln -sf examples/moulin_etal_2019/eqns_moulin_etal_2019.idp eqns.idp
ln -sf examples/moulin_etal_2019/settings_moulin_etal_2019.idp settings.idp
```

## Build initial meshes
In 3D, `ff-bifbox` uses `mshmet`+`mmg` for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine. In this example, we use the mesh `FlatPlate3D.mesh` provided by the authors, which has an aspect ratio of L = 2.5. The original mesh file can be accessed via GitHub at `https://github.com/prj-/moulin2019al`.

## Perform parallel computations using `ff-bifbox`

### Steady dynamics
1. Compute a base state on the mesh at Re = 50 from default guess
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi FlatPlate3D.mesh -fo 3Dwake -1/Re 0.02 -gamma 0.6
```

2. Continue base state along 1/Re from Re = 50 solution.
```
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi 3Dwake.base -param 1/Re -h0 -5 -kmax 4 -snes_max_it 20 -scount 2 -maxcount 4
```

3. Compute a base state on the mesh at Re = 100 with guess from continuation
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi 3Dwake_4.base -fo 3Dwake100 -1/Re 0.01
```

### Unsteady dynamics
4. Compute leading eigenvalue at Re = 100. This is very slow unless massively parallelized.
```
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi 3Dwake100.base -fo 3Dwake -eps_target 0.1+0.6i -eps_nev 5 -eps_ncv 15 -eps_tol 1e-6 -recycle 5 -shiftPrecon 1 -st_ksp_converged_reason -eps_pos_gen_non_hermitian
```

5. Compute optimal resolvent gain at Re = 50. This is very slow unless massively parallelized.
```
ff-mpirun -np $nproc rslvcompute.edp -v 0 -dir $workdir -fi 3Dwake.base -fo 3Dwake -omega 1 -recycle 5 -shiftPrecon 1 -eps_tol 1e-6
```
