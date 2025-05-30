# 2D Incompressible Flow Example: Pralits, et al., JFM. (2010)
This file shows an example `ff-bifbox` workflow for reproducing the results of the paper:
```
@article{pralits_etal_2010,
  title={Instability and sensitivity of the flow around a rotating circular cylinder},
  volume={650},
  DOI={10.1017/S0022112009993764},
  journal={Journal of Fluid Mechanics},
  publisher={Cambridge University Press},
  author={Pralits, Jan O. and Brandt, Luca and Giannetti, Flavio},
  year={2010},
  pages={513–536}
}
```
The commands below illustrate how to analyze the 2D incompressible flow around a rotating cylinder using `ff-bifbox`.

Note that, in this example, viscosity is parameterized by $1/Re$ instead of $Re$ in order to make the equation system linear with respect to the control parameter. Though such scalings do improve the performance of predictor-corrector methods and weakly-nonlinear analysis, `ff-bifbox` does not require the system to be linear in the parameters.

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory and number of processors for easy reference.
```
export workdir=examples/pralits_etal_2010/data
export nproc=4
```
3. Create symbolic links for governing equations and solver settings.
```
ln -sf examples/pralits_etal_2010/eqns_pralits_etal_2010.idp eqns.idp
ln -sf examples/pralits_etal_2010/settings_pralits_etal_2010.idp settings.idp
```

## Build initial meshes using BAMG in FreeFEM
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
```
FreeFem++-mpi -v 0 examples/pralits_etal_2010/cylinder.edp -mo $workdir/cylinder
```

## Perform parallel computations using `ff-bifbox`

### Nonlinear steady states and saddle--node bifurcations
1. Compute base states on the created meshes at $Re=10$, $\alpha=0$ from default guess
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi cylinder.msh -fo cylinder -1/Re 0.1 -alpha 0
```

2. Continue base state along the parameter $1/Re$ with adaptive remeshing
```
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi cylinder.base -fo cylinder -param 1/Re -h0 -10 -scount 2 -maxcount 6 -mo cylinder -thetamax 1
```

3. Compute base states at $Re=50$ and $Re=100$ with guesses from continuation
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi cylinder_4.base -fo cylinder50 -1/Re 0.02
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi cylinder_6.base -fo cylinder100 -1/Re 0.01
```

4. Continue $Re=100$ base state along the parameter $\alpha$ with adaptive remeshing
```
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi cylinder100.base -fo cylinder100 -param alpha -h0 4 -scount 5 -maxcount 120 -mo cylinder100 -thetamax 1 -hmin 5e-3 -dmax 1 -err 0.005
```
NOTE: care should be taken to ensure that the continuation does not jump from one branch to another when the mesh is adapted within the multistable parameter region.

5. Compute backward and forward fold bifurcations from steady solution branch
```
cd $workdir && declare -a foldguesslist=(*specialpt.base) && cd -
//note some shells may index from 1 and 2 instead of 0 and 1
ff-mpirun -np $nproc foldcompute.edp -v 0 -dir $workdir -fi ${foldguesslist[0]} -fo cylinder100_B -param alpha -nf 0
ff-mpirun -np $nproc foldcompute.edp -v 0 -dir $workdir -fi ${foldguesslist[1]} -fo cylinder100_F -param alpha -nf 0
```

6. Adapt the mesh to the critical base/direct/adjoint solutions, save `.vtu` files for Paraview
```
ff-mpirun -np $nproc foldcompute.edp -v 0 -dir $workdir -fi cylinder100_B.fold -fo cylinder100_B -mo cylinder100_B -adaptto bda -param alpha -pv 1 -thetamax 1 -hmin 5e-3 -dmax 1 -err 0.005
ff-mpirun -np $nproc foldcompute.edp -v 0 -dir $workdir -fi cylinder100_F.fold -fo cylinder100_F -mo cylinder100_F -adaptto bda -param alpha -pv 1 -thetamax 1 -hmin 5e-3 -dmax 1 -err 0.005
```
7. Continue the neutral fold curve in the $(1/Re,\alpha)$-plane with adaptive remeshing
```
ff-mpirun -np $nproc foldcontinue.edp -v 0 -dir $workdir -fi cylinder100_B.fold -fo cylinder -mo cylinderfold -adaptto bda -thetamax 1 -hmin 5e-3 -dmax 1 -err 0.005 -param 1/Re -param2 alpha -h0 4 -scount 4 -maxcount 12
```
NOTE: This will return a guess for the location of the cusp bifurcation as `cylinder_*specialpoint.fold`.

### Hopf Bifurcations
8. Compute direct eigenmode at $Re=50$, $\alpha=0$
```
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi cylinder50.base -fo cylindermode1 -eps_target 0.1+0.8i -eps_pos_gen_non_hermitian
```

9. Compute direct eigenmode at $Re=100$, $\alpha=4.8$
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi cylinder100_70.base -fo cylinder4p8 -1/Re 0.01 -alpha 4.8
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi cylinder4p8.base -fo cylindermode2 -eps_target 0.1+0.2i -eps_pos_gen_non_hermitian
```

10. Compute the critical point and critical base/direct/adjoint solution
```
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi cylindermode1.mode -fo cylindermode1 -param 1/Re -nf 0
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi cylindermode2.mode -fo cylindermode2 -param alpha -nf 0
```

11. Adapt the mesh to the critical solutions, save `.vtu` files for Paraview
```
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi cylindermode1.hopf -fo cylindermode1 -mo cylindermode1hopf -adaptto bda -param 1/Re -thetamax 1 -hmin 5e-3 -dmax 1 -err 0.005 -pv 1
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi cylindermode2.hopf -fo cylindermode2 -mo cylindermode2hopf -adaptto bda -param alpha -thetamax 1 -hmin 5e-3 -dmax 1 -err 0.005 -pv 1
```

12. Continue the neutral Hopf curves in the $(1/Re,\alpha)$-plane with adaptive remeshing
```
ff-mpirun -np $nproc hopfcontinue.edp -v 0 -dir $workdir -fi cylindermode1.hopf -fo cylindermode1 -mo cylindermode1hopf -adaptto bda -thetamax 1 -hmin 5e-3 -dmax 1 -err 0.005 -param alpha -param2 1/Re -h0 4 -scount 4 -maxcount 12
ff-mpirun -np $nproc hopfcontinue.edp -v 0 -dir $workdir -fi cylindermode2.hopf -fo cylindermode2 -mo cylindermode2hopf -adaptto bda -thetamax 1 -hmin 5e-3 -dmax 1 -err 0.005 -param 1/Re -param2 alpha -h0 4 -scount 4 -maxcount 12
```
