# 3D Incompressible Wake Flow Example: Marquet and Larsson, (2015)
This file shows an example `ff-bifbox` workflow for reproducing the results of the study:
```
@article{Marquet_larsson_2015,
title = {Global wake instabilities of low aspect-ratio flat-plates},
journal = {European Journal of Mechanics - B/Fluids},
volume = {49},
pages = {400-412},
year = {2015},
note = {Trends in Hydrodynamic Instability in honour of Patrick Huerre's 65th birthday},
issn = {0997-7546},
doi = {10.1016/j.euromechflu.2014.05.005},
author = {O. Marquet and M. Larsson},
}
```
The commands below illustrate how to run the perform a stability analysis of 3D wake behind a rectangular plate using `ff-bifbox`. Note that unlike the example in `examples/moulin_etal_2019`, this study leverages direct methods, so bifurcation points (fold, hopf, etc.) can be located.

IMPORTANT NOTE: The ability to solve 3 dimensional problems in ff-bifbox is still under development! In particular, 3D mesh adaptation with `mmg3d` may contain bugs. 

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```

2. Export working directory and number of processors for easy reference.
```
export workdir=examples/marquet_larsson_2015/data
export nproc=4
```

3. Create symbolic links for governing equations and solver settings.
```
ln -sf examples/marquet_larsson_2015/eqns_marquet_larsson_2015.idp eqns.idp
ln -sf examples/marquet_larsson_2015/settings_marquet_larsson_2015.idp settings.idp
```

## Build initial meshes
In 3D, `ff-bifbox` uses `mshmet`+`mmg` for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine. The example code here does not include arguments for mesh adaptation, as mesh adaptation in 3D using `mshmet`+`mmg` is not as robust as in 2D with `adaptmesh`.
#### Build initial mesh directly from `.geo` files using Gmsh
```
FreeFem++-mpi -v 0 importgmsh.edp -gmshdir examples/marquet_larsson_2015 -dir $workdir -mi plate.geo
```
Note: since no `-mo` argument is specified, the output files (`.msh`) inherit the names of their parents (`.geo`).

## Perform parallel computations using `ff-bifbox`

### $y$-antisymmetric, $z$-symmetric mode
1. Compute a base state on the mesh at $Re=60$, $L=6$ from default guess
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi plate.mesh -fo wakeL6Re20 -1/Re 0.05 -L 6
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi wakeL6Re20.base -fo wakeL6Re60 -1/Re 0.01666666666666666666 -L 6
```

2. Compute the leading eigenmode at $Re=60$, $L=6$ that is anti-symmetric along $y$ and symmetric along $z$.
```
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi wakeL6Re60.base -fo wakeL6Re60yAzS -eps_target 0.1+0.6i -sym 1,0 -eps_pos_gen_non_hermitian
```

3. Compute the critical point and critical base/direct/adjoint solution
```
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi wakeL6Re60yAzS.mode -fo wakeL6Re60yAzS -param 1/Re -nf 0
```

4. Continue the neutral Hopf curve in the $(1/Re, L)$-plane
```
ff-mpirun -np $nproc hopfcontinue.edp -v 0 -dir $workdir -fi wakeL6Re60yAzS.hopf -fo wakeL6Re60yAzS -param L -param2 1/Re -h0 -4 -scount 4 -maxcount 12
```

### $y$-symmetric, $z$-antisymmetric mode
5. Compute a base state on the mesh at $Re=100$, $L=3$ from guess at $Re=60$, $L=6$
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi wakeL6Re60.base -fo wakeL3Re100 -1/Re 0.01 -L 3
```

6. Compute the leading eigenmode at $Re=100$, $L=3$ that is symmetric along $y$ and anti-symmetric along $z$.
```
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi wakeL3Re100.base -fo wakeL3Re100ySzA -eps_target 0.1+0.3i -sym 0,1 -eps_pos_gen_non_hermitian
```

7. Compute the critical point and critical base/direct/adjoint solution
```
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi wakeL3Re100ySzA.mode -fo wakeL3Re100ySzA -param 1/Re -nf 0
```

8. Continue the neutral Hopf curve in the $(1/Re, L)$-plane
```
ff-mpirun -np $nproc hopfcontinue.edp -v 0 -dir $workdir -fi wakeL3Re100ySzA.hopf -fo wakeL3Re100ySzA -param L -param2 1/Re -h0 -4 -scount 4 -maxcount 12
```

### $y$-symmetric, $z$-antisymmetric mode
9. Compute a base state on the mesh at $Re\sim105$, $L=1.5$ from guess at $Re=100$, $L=3$
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi wakeL3Re100.base -fo wakeL1p5Re105 -1/Re 0.0095 -L 1.5
```

10. Compute the leading stationary eigenmode at $Re\sim105$, $L=1.5$ that is antisymmetric along $y$ and symmetric along $z$.
```
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi wakeL1p5Re105.base -fo wakeL1p5Re105yAzS -eps_target 0.1+0.0i -sym 1,0 -eps_pos_gen_non_hermitian
```

11. Compute the critical point and critical base/direct/adjoint solution
```
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi wakeL1p5Re105yAzS.mode -fo wakeL1p5Re105yAzS -param 1/Re -nf 0 -zero 1
```

12. Continue the neutral Hopf curve in the $(1/Re, L)$-plane
```
ff-mpirun -np $nproc hopfcontinue.edp -v 0 -dir $workdir -fi wakeL1p5Re105yAzS.hopf -fo wakeL1p5Re105yAzS -param L -param2 1/Re -h0 4 -scount 4 -maxcount 12 -zero 1
```

### double-Hopf point for $y$/$z$ symmetry/antisymmetry switch
13. Compute a base state on the mesh at $Re=100$, $L=2.5$ from guess at $Re=100$, $L=3$
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi wakeL3Re100.base -fo wakeL2p5Re100 -1/Re 0.01 -L 2.5
```

14. Compute the leading stationary eigenmodes.
```
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi wakeL2p5Re100.base -fo wakeL2p5Re100yAzS -eps_target 0.1+0.5i -sym 1,0 -eps_pos_gen_non_hermitian
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi wakeL2p5Re100.base -fo wakeL2p5Re100ySzA -eps_target 0.1+0.25i -sym 0,1 -eps_pos_gen_non_hermitian
```

15. Compute the critical point and critical base/direct/adjoint solution
```
ff-mpirun -np $nproc hohocompute.edp -v 0 -dir $workdir -fi wakeL2p5Re100yAzS.mode -fi2 wakeL2p5Re100ySzA.mode -fo wakeL2p5Re100 -param 1/Re -param2 L
```

### Hopf-pitchfork point for $y$/$z$ symmetry/antisymmetry switch
16. Compute a base state on the mesh at $Re=105$, $L=2$ from guess at $Re=100$, $L=3$
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi wakeL2pRe100.base -fo wakeL3Re95 -1/Re 0.0095 -L 2
```

17. Compute the leading stationary eigenmodes.
```
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi wakeL2p5Re100.base -fo wakeL2p5Re100yAzS -eps_target 0.1+0.5i -sym 1,0 -eps_pos_gen_non_hermitian
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi wakeL2p5Re100.base -fo wakeL2p5Re100ySzA -eps_target 0.1+0.25i -sym 0,1 -eps_pos_gen_non_hermitian
```

18. Compute the critical point and critical base/direct/adjoint solution
```
ff-mpirun -np $nproc hohocompute.edp -v 0 -dir $workdir -fi wakeL2p5Re100yAzS.mode -fi2 wakeL2p5Re100ySzA.mode -fo wakeL2p5Re100 -param 1/Re -param2 L
```
