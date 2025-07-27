# Incompressible Swirling Jet Example: Douglas etal, JFM, (2021)
This file shows an example `ff-bifbox` workflow for reproducing the results of the study:
```tex
@article{douglas_etal_2021,
  title={Nonlinear dynamics of fully developed swirling jets},
  volume={924},
  DOI={10.1017/jfm.2021.615},
  journal={Journal of Fluid Mechanics},
  publisher={Cambridge University Press},
  author={Douglas, Christopher M. and Emerson, Benjamin L. and Lieuwen, Timothy C.},
  year={2021},
  pages={A14}
}
```
The commands below illustrate how to perform a bifurcation analysis of an incompressible swirling jet using `ff-bifbox`.

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```sh
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory and number of processors for easy reference.
```sh
export workdir=examples/douglas_etal_2021/data
export nproc=4
```
3. Create symbolic links for governing equations and solver settings.
```sh
ln -sf examples/douglas_etal_2021/eqns_douglas_etal_2021.idp eqns.idp
ln -sf examples/douglas_etal_2021/settings_douglas_etal_2021.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from `.geo` files
```sh
FreeFem++-mpi -v 0 importgmsh.edp -gmshdir examples/douglas_etal_2021 -dir $workdir -mi swirljet.geo
```
Note: since no `-mo` argument is specified, the output files (`.msh`) inherit the names of their parents (`.geo`).
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```sh
FreeFem++-mpi -v 0 examples/douglas_etal_2021/swirljet.edp -mo $workdir/swirljet
```

## Perform parallel computations using `ff-bifbox`
### Steady axisymmetric dynamics
1. Compute base states on the created mesh at $Re=10$ from default guess
```sh
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi swirljet.msh -fo swirljet -1/Re 0.1 -S 0
```

2. Continue base state along the parameter $1/Re$ with adaptive remeshing
```sh
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi swirljet.base -fo swirljet -param 1/Re -h0 -50 -scount 2 -maxcount 4 -mo swirljet -thetamax 1
```

3. Compute base state at $Re=100$ with guess from $1/Re$ continuation
```sh
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi swirljet_4.base -fo swirljet100 -1/Re 0.01
```

4. Continue base state at $Re=100$ along the parameter $S$ with adaptive remeshing
```sh
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi swirljet100.base -fo swirljet100 -param S -h0 5 -scount 5 -maxcount -1 -mo swirljet100 -thetamax 1 -paramtarget 3
```

5. Compute backward and forward fold bifurcations from steady solution branch on base-adapted mesh
```sh
cd $workdir && declare -a foldguesslist=(*specialpt.base) && cd -
//note some shells may index from 1 and 2 instead of 0 and 1
ff-mpirun -np $nproc foldcompute.edp -v 0 -dir $workdir -fi ${foldguesslist[0]} -fo swirljet100_B -param S -mo swirljet100_B -adaptto b -thetamax 1 -nf 0
ff-mpirun -np $nproc foldcompute.edp -v 0 -dir $workdir -fi ${foldguesslist[1]} -fo swirljet100_F -param S -mo swirljet100_F -adaptto b -thetamax 1 -nf 0
```

6. Adapt the mesh to the critical base/direct/adjoint solutions, save `.vtu` files for Paraview
```sh
ff-mpirun -np $nproc foldcompute.edp -v 0 -dir $workdir -fi swirljet100_B.fold -fo swirljet100_B -mo swirljet100_B -adaptto bda -param S -pv 1 -thetamax 1
ff-mpirun -np $nproc foldcompute.edp -v 0 -dir $workdir -fi swirljet100_F.fold -fo swirljet100_F -mo swirljet100_F -adaptto bda -param S -pv 1 -thetamax 1
```

7. Continue the neutral fold curve in the $(1/Re,S)$-plane with adaptive remeshing
```sh
ff-mpirun -np $nproc foldcontinue.edp -v 0 -dir $workdir -fi swirljet100_B.fold -fo swirljet -mo swirljetfold -adaptto bda -thetamax 1 -param 1/Re -param2 S -h0 4 -scount 4 -maxcount 32
```

### Bifurcations to unsteady, 3D dynamics
8. Compute base state at $Re=133$, $S=1.8$ with guess from $Re=100$ continuation along $S$
```sh
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi swirljet100_10.base -fo swirljet1p8 -1/Re 0.0075 -S 1.8
```

9. Compute leading $|m|=1$ and $|m|=2$ eigenvalues
```sh
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi swirljet1p8.base -fo swirljet1p8m1 -eps_target 0.1-0.8i -sym -1 -eps_pos_gen_non_hermitian
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi swirljet1p8.base -fo swirljet1p8m2 -eps_target 0.1+0.4i -sym -2 -eps_pos_gen_non_hermitian
```

10. Compute Hopf bifurcation points
```sh
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi swirljet1p8m1.mode -fo swirljetm1 -param 1/Re -nf 0
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi swirljet1p8m2.mode -fo swirljetm2 -param 1/Re -nf 0
```

11. Adapt the mesh to the critical base/direct/adjoint solutions, save `.vtu` files for Paraview
```sh
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi swirljetm1.hopf -fo swirljetm1 -param 1/Re -mo swirljetm1 -adaptto bda -pv 1 -thetamax 1
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi swirljetm2.hopf -fo swirljetm2 -param 1/Re -mo swirljetm2 -adaptto bda -pv 1 -thetamax 1
```

12. Continue the neutral Hopf curves in the $(1/Re,S)$-plane with adaptive remeshing
```sh
ff-mpirun -np $nproc hopfcontinue.edp -v 0 -dir $workdir -fi swirljetm1.hopf -fo swirljetm1 -mo swirljetm1hopf -adaptto bda -thetamax 1 -param 1/Re -param2 S -h0 4 -scount 4 -maxcount 32
ff-mpirun -np $nproc hopfcontinue.edp -v 0 -dir $workdir -fi swirljetm2.hopf -fo swirljetm2 -mo swirljetm2hopf -adaptto bda -thetamax 1 -param 1/Re -param2 S -h0 4 -scount 4 -maxcount 12
```

13. Compute the Hopf-Hopf point where the $|m|=1$ and $|m|=2$ curves cross
```sh
ff-mpirun -np $nproc hohocompute.edp -v 0 -dir $workdir -fi swirljetm2.hopf -fi2 swirljetm1.hopf -fo swirljetm2m1 -param 1/Re -param2 S -nf 0
ff-mpirun -np $nproc hohocompute.edp -v 0 -dir $workdir -fi swirljetm2m1.hoho -fo swirljetm2m1 -param 1/Re -param2 S -mo swirljetm2m1 -adaptto bda -pv 1 -thetamax 1
```

14. Compute the fold-Hopf point where the $|m|=1$ curve intersects the fold curve
```sh
cd $workdir && declare -a fohoguesslist=(*specialpt.hopf) && cd -
ff-mpirun -np $nproc fohocompute.edp -v 0 -dir $workdir -fi ${fohoguesslist[1]} -fo swirljetm1 -param S -param2 1/Re -snes_divergence_tolerance 1e10
```

### Periodic 3D dynamics
15. Continue periodic solutions along $S$ from their initial Hopf points using the harmonic balance method with $N_h=2$.
```sh
ff-mpirun -np $nproc porbcontinue.edp -v 0 -dir $workdir -fi swirljetm1.hopf -fo swirljetm1 -Nh 2 -mo swirljetm1porb -param S -thetamax 1 -h0 0.5 -scount 4 -maxcount 12
ff-mpirun -np $nproc porbcontinue.edp -v 0 -dir $workdir -fi swirljetm2.hopf -fo swirljetm2 -Nh 2 -mo swirljetm2porb -param S -thetamax 1 -h0 -0.5 -scount 4 -maxcount 16
```
NOTE: in the actual paper, $N_h=4$ to $6$ was used to accurately resolve the periodic orbits. $N_h=2$ is used here to reduce computational cost.

16. Compute periodic solutions at $S=1.9$ ($|m|=1$) and $S=1.8$ ($|m|=2$) with $N_h=3$ using a block preconditioner.
```sh
ff-mpirun -np $nproc porbcompute.edp -v 0 -dir $workdir -fi swirljetm1_12.porb -fo swirljetm1 -Nh 3 -S 1.9 -blocks 3
ff-mpirun -np $nproc porbcompute.edp -v 0 -dir $workdir -fi swirljetm2_16.porb -fo swirljetm2 -Nh 3 -S 1.8 -blocks 3
```

### Bifurcations to aperiodic 3D dynamics
17. Compute Floquet stability of periodic solutions against each other 
```sh
ff-mpirun -np $nproc floqcompute.edp -v 0 -dir $workdir -fi swirljetm1.porb -fo swirljetm1 -Nh 3 -eps_target 0.1+0.3i -sym -2 -S 1.9 -blocks 3 -eps_pos_gen_non_hermitian
ff-mpirun -np $nproc floqcompute.edp -v 0 -dir $workdir -fi swirljetm2.porb -fo swirljetm2 -Nh 3 -eps_target 0.02-0.75i -sym -1 -S 1.8 -blocks 3 -eps_pos_gen_non_hermitian
```