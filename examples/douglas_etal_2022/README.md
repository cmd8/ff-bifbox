# Incompressible Swirling Annual Jet Example: Douglas etal, JFM, (2022)
This file shows an example `ff-bifbox` workflow for reproducing the results in the study:
```tex
@article{douglas_etal_2022,
  title={Dynamics and bifurcations of laminar annular swirling and non-swirling jets},
  volume={943},
  DOI={10.1017/jfm.2022.453},
  journal={Journal of Fluid Mechanics},
  publisher={Cambridge University Press},
  author={Douglas, Christopher M. and Emerson, Benjamin L. and Lieuwen, Timothy C.},
  year={2022},
  pages={A35}
}
```
The commands below illustrate how to perform a bifurcation analysis of an incompressible swirling annular jet using `ff-bifbox`.

NOTE: This code uses computational coordinates that differ from the physical coordinates by a scaling factor related to the parameter $d$ (see the `Y()` macro in `eqns_douglas_etal_2022.idp`). Paraview files are printed on the computational coordinates so this coordinate transormation must be taken into consideration at the visualization stage.

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```sh
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory and number of processors for easy reference.
```sh
export workdir=examples/douglas_etal_2022/data
export nproc=4
```
3. Create symbolic links for governing equations and solver settings.
```sh
ln -sf examples/douglas_etal_2022/eqns_douglas_etal_2022.idp eqns.idp
ln -sf examples/douglas_etal_2022/settings_douglas_etal_2022.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from `.geo` files
```sh
FreeFem++-mpi -v 0 importgmsh.edp -gmshdir examples/douglas_etal_2022 -dir $workdir -mi annularjet.geo
```
Note: since no `-mo` argument is specified, the output files (`.msh`) inherit the names of their parents (`.geo`).
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```sh
FreeFem++-mpi -v 0 examples/douglas_etal_2022/annularjet.edp -mo $workdir/annularjet
```

## Perform parallel computations using `ff-bifbox`
### Steady axisymmetric dynamics
1. Compute base states on the created mesh at $Re=20$ from default guess
```sh
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi annularjet.msh -fo annularjet -1/Re 0.05 -S 0 -d 0.5
```

2. Continue base state along the parameter $1/Re$ with adaptive remeshing
```sh
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi annularjet.base -fo annularjet -param 1/Re -h0 -100 -scount 2 -maxcount 10 -mo annularjet -thetamax 1
```

3. Compute base state at $Re=100$ with guess from $1/Re$ continuation
```sh
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi annularjet_6.base -fo annularjet100 -1/Re 0.01
```

4. Continue base state at $Re=100$ along the parameter $S$ with adaptive remeshing
```sh
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi annularjet100.base -fo annularjet100 -param S -h0 20 -scount 5 -maxcount -1 -mo annularjet100 -thetamax 1 -paramtarget 3
```

5. Compute backward and forward fold bifurcations from steady solution branch on base-adapted mesh
```sh
cd $workdir && declare -a foldguesslist=(*specialpt.base) && cd -
//note some shells may index from 1 and 2 instead of 0 and 1
ff-mpirun -np $nproc foldcompute.edp -v 0 -dir $workdir -fi ${foldguesslist[0]} -fo annularjet100_B -param S -mo annularjet100_B -adaptto b -thetamax 1 -nf 0
ff-mpirun -np $nproc foldcompute.edp -v 0 -dir $workdir -fi ${foldguesslist[1]} -fo annularjet100_F -param S -mo annularjet100_F -adaptto b -thetamax 1 -nf 0
```

6. Adapt the mesh to the critical base/direct/adjoint solutions, save `.vtu` files for Paraview
```sh
ff-mpirun -np $nproc foldcompute.edp -v 0 -dir $workdir -fi annularjet100_B.fold -fo annularjet100_B -mo annularet100_B -adaptto bda -param S -pv 1 -thetamax 1
ff-mpirun -np $nproc foldcompute.edp -v 0 -dir $workdir -fi annularjet100_F.fold -fo annularjet100_F -mo annularjet100_F -adaptto bda -param S -pv 1 -thetamax 1
```

7. Continue the neutral fold curve in the $(1/Re,S)$-plane and $(d,S)$-plane with adaptive remeshing
```sh
ff-mpirun -np $nproc foldcontinue.edp -v 0 -dir $workdir -fi annularjet100_B.fold -fo annularjet_ReS -mo annularjet_ReSfold -adaptto bda -thetamax 1 -param 1/Re -param2 S -h0 4 -scount 4 -maxcount 32
ff-mpirun -np $nproc foldcontinue.edp -v 0 -dir $workdir -fi annularjet100_B.fold -fo annularjet_dS -mo annularjet_dSfold -adaptto bda -thetamax 1 -param d -param2 S -h0 4 -scount 4 -maxcount 32
```

### Steady 3D dynamics
8. Compute base state at $Re\sim480$ with guess from $1/Re$ continuation
```sh
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi annularjet_10.base -fo annularjet480 -1/Re 0.002095
```

9. Compute leading $|m|=1$ eigenvalue
```sh
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi annularjet480.base -fo annularjet480m1 -eps_target 0.1-0i -sym -1 -eps_pos_gen_non_hermitian
```

10. Compute zero-Hopf bifurcation point
```sh
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi annularjet480m1.mode -fo annularjetm1 -zero 1 -param 1/Re -nf 0
```

11. Adapt to zero-Hopf point and compute normal form
```sh
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi annularjetm1.hopf -fo annularjetm1 -param 1/Re -mo annularjetm1 -adaptto bda -pv 1 -thetamax 1 -zero 1
```

12. Continue the neutral zero-Hopf curve in the $(1/Re,d)$-plane with adaptive remeshing
```sh
ff-mpirun -np $nproc hopfcontinue.edp -v 0 -dir $workdir -fi annularjetm1.hopf -fo annularjetm1 -mo annularjetm1hopf -adaptto bda -thetamax 1 -param 1/Re -param2 d -h0 20 -scount 4 -maxcount 32 -zero 1
```