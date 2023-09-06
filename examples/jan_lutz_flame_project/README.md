# README for the project of Jan, Lutz, Chris, Chuhan, beginning Fall 2023

The commands below illustrate how to analyze a 2D reacting compressible flow through a duct and around a cylinder using `ff-bifbox`.

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory for easy reference.
```
export workdir=examples/jan_lutz_flame_project
```
3. Create symbolic links for governing equations and solver settings.
### CASE 1: non-reacting case
```
ln -sf examples/jan_lutz_flame_project/eqns_comp.idp eqns.idp
ln -sf examples/jan_lutz_flame_project/settings_comp.idp settings.idp
```
### CASE 2: reacting case
```
ln -sf examples/jan_lutz_flame_project/eqns_compreact.idp eqns.idp
ln -sf examples/jan_lutz_flame_project/settings_compreact.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### build initial mesh using BAMG in FreeFEM
```
FreeFem++-mpi -v 0 examples/jan_lutz_flame_project/cylinder.edp -mo $workdir/cylinder
```

## Perform parallel computations using `ff-bifbox`
The number of processors is set using the `-n` argument from `mpirun`. Here, this value is set to 4.
### Zeroth order
1. Compute base state on the created mesh at Re = 10 from default guess
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir $workdir -mi cylinder.msh -fo cylinder -Re 10 -Pr 0.7 -Ma 0.1 -ga 1.4
```

2. Continue base state along the parameter Re with adaptive remeshing
```
mpirun -n 4 FreeFem++-mpi -v 0 basecontinue.edp -dir $workdir -fi cylinder.base -fo cylinder -param Re -h0 1 -scount 2 -maxcount 10 -mo cylinder -thetamax 1
```
