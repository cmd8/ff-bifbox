# 2D Incompressible Swirling Flow Example: Douglas etal, JFM, (2021)
This file shows an example `ff-bifbox` workflow for reproducing the results in section 4 of the study:
```
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
```
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory for easy reference.
```
export workdir=examples/douglas_etal_2021
```
3. Create symbolic links for governing equations and solver settings.
```
ln -sf $workdir/eqns_douglas_etal_2021.idp eqns.idp
ln -sf $workdir/settings_douglas_etal_2021.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from .geo files
```
FreeFem++-mpi -v 0 importgmsh.edp -dir $workdir -mi swirljet.geo
```
Note: since no `-mo` argument is specified, the output files (.msh) inherit the names of their parents (.geo).
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```
FreeFem++-mpi -v 0 $workdir/swirljet.edp -mo $workdir/swirljet
```

## Perform parallel computations using `ff-bifbox`
The number of processors is set using the `-n` argument from `mpirun`. Here, this value is set to 4.
### Steady axisymmetric dynamics
1. Compute base states on the created mesh at Re = 10 from default guess
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -mi swirljet.msh -fo swirljet -1/Re 0.1 -S 0
```

2. Continue base state along the parameter 1/Re with adaptive remeshing
```
mpirun -n 4 FreeFem++-mpi -v 0 basecontinue.edp -dir $workdir -fi swirljet.base -fo swirljet -param 1/Re -h0 -1 -scount 2 -maxcount 10 -mo swirljet -thetamax 1
```

3. Compute base state at Re = 100 with guess from 1/Re continuation
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -fi swirljet_10.base -fo swirljet100 -1/Re 0.01
```

4. Continue base state at Re = 100 along the parameter S with adaptive remeshing
```
mpirun -n 4 FreeFem++-mpi -v 0 basecontinue.edp -dir $workdir -fi swirljet100.base -fo swirljet100 -param S -h0 5 -scount 5 -maxcount 100 -mo swirljet100 -thetamax 1
```

5. Compute backward and forward fold bifurcations from steady solution branch on base-adapted mesh
```
cd $workdir && declare -a foldguesslist=(*foldguess.base) && cd -
mpirun -n 4 FreeFem++-mpi -v 0 foldcompute.edp -dir $workdir -fi ${foldguesslist[0]} -fo swirljet100_B -param S -mo swirljet100_B -adaptto b -thetamax 1
mpirun -n 4 FreeFem++-mpi -v 0 foldcompute.edp -dir $workdir -fi ${foldguesslist[1]} -fo swirljet100_F -param S -mo swirljet100_F -adaptto b -thetamax 1
```

6. Adapt the mesh to the critical base/direct/adjoint solutions, save .vtu files for Paraview
```
mpirun -n 4 FreeFem++-mpi -v 0 foldcompute.edp -dir $workdir -fi swirljet100_B.fold -fo swirljet100_B -mo swirljet100_B -adaptto bda -param S -pv 1 -thetamax 1
mpirun -n 4 FreeFem++-mpi -v 0 foldcompute.edp -dir $workdir -fi swirljet100_F.fold -fo swirljet100_F -mo swirljet100_F -adaptto bda -param S -pv 1 -thetamax 1
```

7. Continue the neutral fold curve in the (1/Re,S)-plane with adaptive remeshing
```
mpirun -n 4 FreeFem++-mpi -v 0 foldcontinue.edp -dir $workdir -fi swirljet100_B.fold -fo swirljet -mo swirljetfold -adaptto bda -thetamax 1 -param1 1/Re -param2 S -h0 4 -scount 4 -maxcount 32
```

### Unsteady 3D dynamics
8. Compute base state at Re = 133, S = 1.8 with guess from Re = 100 continuation along S
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -fi swirljet_10.base -fo swirljet1p8 -1/Re 0.0075 -S 1.8
```

9. Compute leading |m| = 1 and |m| = 2 eigenvalues
```
mpirun -n 4 FreeFem++-mpi -v 0 modecompute.edp -dir $workdir -fi swirljet1p8.base -fo swirljet1p8m1 -so "" -eps_target 0.1-0.8i -sym -1
mpirun -n 4 FreeFem++-mpi -v 0 modecompute.edp -dir $workdir -fi swirljet1p8.base -fo swirljet1p8m2 -so "" -eps_target 0.1+0.4i -sym -2
```

10. Compute Hopf bifurcation points
```
mpirun -n 4 FreeFem++-mpi -v 0 hopfcompute.edp -dir $workdir -fi swirljet1p8m1_0.mode -fo swirljetm1 -param 1/Re
mpirun -n 4 FreeFem++-mpi -v 0 hopfcompute.edp -dir $workdir -fi swirljet1p8m2_0.mode -fo swirljetm2 -param 1/Re
```

11. Adapt the mesh to the critical base/direct/adjoint solutions, save .vtu files for Paraview
```
mpirun -n 4 FreeFem++-mpi -v 0 hopfcompute.edp -dir $workdir -fi swirljetm1.hopf -fo swirljetm1 -param 1/Re -mo swirljetm1 -adaptto bda -pv 1 -thetamax 1
mpirun -n 4 FreeFem++-mpi -v 0 hopfcompute.edp -dir $workdir -fi swirljetm2.hopf -fo swirljetm2 -param 1/Re -mo swirljetm2 -adaptto bda -pv 1 -thetamax 1
```

12. Compute 2nd-order weakly-nonlinear analysis, save .vtu files for Paraview
```
mpirun -n 4 FreeFem++-mpi -v 0 wnl2compute.edp -dir $workdir -fi swirljetm1.hopf -fo swirljetm1 -param 1/Re -pv 1
mpirun -n 4 FreeFem++-mpi -v 0 wnl2compute.edp -dir $workdir -fi swirljetm2.hopf -fo swirljetm2 -param 1/Re -pv 1
```

13. Continue the neutral Hopf curves in the (1/Re,S)-plane with adaptive remeshing
```
mpirun -n 4 FreeFem++-mpi -v 0 hopfcontinue.edp -dir $workdir -fi swirljetm1.hopf -fo swirljetm1 -mo swirljetm1hopf -adaptto bda -thetamax 1 -param1 1/Re -param2 S -h0 4 -scount 4 -maxcount 20
mpirun -n 4 FreeFem++-mpi -v 0 hopfcontinue.edp -dir $workdir -fi swirljetm2.hopf -fo swirljetm2 -mo swirljetm2hopf -adaptto bda -thetamax 1 -param1 1/Re -param2 S -h0 4 -scount 4 -maxcount 12
```

14. Compute the double-Hopf point where the |m| = 1 and |m| = 2 curves cross
```
mpirun -n 4 FreeFem++-mpi -v 0 doublehopfcompute.edp -dir $workdir -fi1 swirljetm2.hopf -fi2 swirljetm1.hopf -fo1 swirljetm2double -fo2 swirljetm1double -param1 1/Re -param2 S
mpirun -n 4 FreeFem++-mpi -v 0 doublehopfcompute.edp -dir $workdir -fi1 swirljetm2double.hopf -fi2 swirljetm1double.hopf -fo2 swirljetm2double -fo1 swirljetm1double -param1 1/Re -param2 S -mo swirljetm1m2double -adaptto bda -pv 1 -thetamax 1
```

15. Compute the zero-Hopf point where the |m| = 1 curve intersects the fold curve
```
mpirun -n 4 FreeFem++-mpi -v 0 zerohopfcompute.edp -dir $workdir -fi1 swirljetm1_20.hopf -fo1 swirljetm1zero -fo2 swirljetm1zero -param1 1/Re -param2 S
mpirun -n 4 FreeFem++-mpi -v 0 zerohopfcompute.edp -dir $workdir -fi1 swirljetm1zero.hopf -fi2 swirljetm1zero.fold -fo1 swirljetm1zero -fo2 swirljetm1zero -param1 1/Re -param2 S -mo swirljetm1zero -adaptto bda -pv 1 -thetamax 1
```
