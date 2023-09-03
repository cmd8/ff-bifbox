# Low-Mach conical flame Example: Douglas et al., CNF, (2023)
This file shows an example `ff-bifbox` workflow for reproducing the results in the study:
```
@phdthesis{douglas_etal_2023,
  title = {{Flash-back, blow-off, and symmetry breaking of premixed conical flames}},
  author = {Douglas, Christopher M. and Polifke, Wolfgang and Lesshafft, Lutz},
  doi = {},
  journal={Combustion and Flame},
  publisher={Elsevier},
  year={2023},
}
```
The commands below illustrate how to perform a resolvent analysis of an incompressible laminar axisymmetric jet using `ff-bifbox`.

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory for easy reference.
```
export workdir=examples/douglas_etal_2023
```
3. Create symbolic links for governing equations and solver settings.
```
ln -sf $workdir/eqns_douglas_etal_2023.idp eqns.idp
ln -sf $workdir/settings_douglas_etal_2023.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from .geo files
```
FreeFem++-mpi -v 0 importgmsh.edp -dir $workdir -mi jet.geo
```
Note: since no `-mo` argument is specified, the output files (.msh) inherit the names of their parents (.geo).
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```
FreeFem++-mpi -v 0 $workdir/jet.edp -mo $workdir/jet
```

## Perform parallel computations using `ff-bifbox`
The number of processors is set using the `-n` argument from `mpirun`. Here, this value is set to 4.
### Laminar base flow
1. Compute a base state on the created mesh at Re = 10, Pr = 0.7, Le = 1, Da = 10, dT = 4, Ze = 1, a = 2/3.
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -mi jet.msh -fo jet -1/Re 0.1 -1/Pr 1.42857142857142857 -1/Le 1 -Da 10 -dT 4 -Ze 1 -a 0.6666666666666667
```

2. Continue base state along the parameters to the desired conditions. This is a complicated step that takes a significant amount of computations/time and involves a lot of trial and error decisions. It is useful to save the outputs to paraview in order to keep track of how the solution is changing as a function of the parameters.
```
mpirun -n 4 FreeFem++-mpi -v 0 basecontinue.edp -dir $workdir -fi jet.base -fo jet -param 1/Re -h0 -30 -scount 2 -maxcount 10 -mo jet -pv 1
```
