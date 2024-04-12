# Low-Mach conical flame Example: Douglas et al., CNF, (2023)
This file shows an example `ff-bifbox` workflow for reproducing the results in the study:
```
@article{douglas_etal_2023,
  title = {{Flash-back, blow-off, and symmetry breaking of premixed conical flames}},
  volume={258},
  author = {Douglas, Christopher M. and Polifke, Wolfgang and Lesshafft, Lutz},
  doi = {10.1016/j.combustflame.2023.113060},
  journal={Combustion and Flame},
  publisher={Elsevier},
  pages = {113060},
  year={2023},
}
```
The commands below illustrate how to perform a bifurcation analysis of a premixed conical flame using `ff-bifbox`.

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory and number of processors for easy reference.
```
export workdir=examples/douglas_etal_2023/data
export nproc=4
```
3. Create symbolic links for governing equations and solver settings.
```
ln -sf examples/douglas_etal_2023/eqns_douglas_etal_2023.idp eqns.idp
ln -sf examples/douglas_etal_2023/settings_douglas_etal_2023.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from .geo files
```
FreeFem++-mpi -v 0 importgmsh.edp -gmshdir examples/douglas_etal_2023 -dir $workdir -mi jet.geo
```
Note: since no `-mo` argument is specified, the output files (.msh) inherit the names of their parents (.geo).
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```
FreeFem++-mpi -v 0 examples/douglas_etal_2023/jet.edp -mo $workdir/jet
```

## Perform parallel computations using `ff-bifbox`
### Laminar base flow
1. Compute a base state on the created mesh at Re = 10, Pr = 0.7, Le = 1, Da = 1, dT = 4, Ze = 0, a = 2/3.
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi jet.msh -fo ignite_0 -Re 10 -Pr 0.7 -Le 1 -Da 1 -dT 4 -Ze 0 -a 0.6666666666666667
```

2. Increase Re to 1000 with adaptive remeshing.
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_0.base -fo ignite_1 -Re 50
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_1.base -fo ignite_2 -Re 120
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_2.base -fo ignite_3 -Re 300
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_3.base -fo ignite_4 -Re 700
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_4.base -fo ignite_5 -Re 1000 -mo ignite_5
```

3. Continue base state along the parameters to the desired conditions. This is a complicated step that takes a significant amount of computations/time and involves a lot of trial and error decisions. It is useful to save the outputs to paraview in order to keep track of how the solution is changing as a function of the parameters.
```
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi ignite_5.base -fo ignite -param Ze -h0 10 -count 5 -scount 5 -maxcount 100 -mo ignite -pv 1
```
