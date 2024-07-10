# 2D Reacting Compressible Flow Example: Brokof et al, PROCI. (2024)
This file shows an example `ff-bifbox` workflow for reproducing the results in the study:
```
@article{brokof_etal_2024,
  title = {The role of hydrodynamic shear in the thermoacoustic response of slit flames},
  journal = {Proceedings of the Combustion Institute},
  volume = {40},
  number = {1},
  pages = {105362},
  year = {2024},
  doi = {10.1016/j.proci.2024.105362},
  author = {Brokof, Philipp and Douglas, Christopher M. and Polifke, Wolfgang},
}
```
The commands below illustrate how to analyze a 2D reacting compressible flow through a duct using `ff-bifbox`.

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory and number of processors for easy reference.
```
export workdir=examples/brokof_etal_2024/data
export nproc=4
```
3. Create symbolic links for governing equations and solver settings.
```
ln -sf examples/brokof_etal_2024/eqns_brokof_etal_2024.idp eqns.idp
ln -sf examples/brokof_etal_2024/settings_brokof_etal_2024.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from .geo files
```
FreeFem++-mpi -v 0 importgmsh.edp -gmshdir examples/brokof_etal_2024 -dir $workdir -mi duct.geo
```
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```
FreeFem++-mpi -v 0 examples/brokof_etal_2024/duct.edp -mo $workdir/duct
```

## Perform parallel computations using `ff-bifbox`
### Zeroth order
1. Compute an initial base state at Re = 200 on the created mesh from default guess
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi duct.msh -fo ignite_0 -Re 200 -Pe 70 -Ma 0.01 -gamma 1.4 -dT 5.67 -Da 1 -Ze 0 -L 1
```

2. Gradually ignite the base flow via continuation of Da and Ze. (slow!)
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_0.base -fo ignite_1 -Ze 1 -mo ignite_1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_1.base -fo ignite_2 -Ze 2 -Da 2 -mo ignite_2
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_2.base -fo ignite_3 -Ze 4 -Da 4 -mo ignite_3
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_3.base -fo ignite_4 -Ze 4.2 -Da 10 -mo ignite_4
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_4.base -fo ignite_5 -Ze 4.5 -Da 20 -mo ignite_5
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_5.base -fo ignite_6 -Ze 5 -Da 30 -mo ignite_6
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_6.base -fo ignite_7 -Ze 6 -Da 50 -mo ignite_7
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_7.base -fo ignite_8 -Ze 7 -Da 70 -mo ignite_8
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_8.base -fo ignite_9 -Ze 8 -Da 80 -mo ignite_9
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_9.base -fo ignite_10 -Ze 10 -Da 100 -mo ignite_10
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi ignite_10.base -fo ignite -param Da -count 10 -h0 10 -maxcount -1 -scount 5 -mo ignite -paramtarget 1700 -dmax 10
```

3. Compute Re = 200, 500, 800 base flow fields at L = 0.5, 1, 5.0. (Change `ignite_190.base` to `ignite_xxx.base` where `xxx` is the highest count value from the continuation.)
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_190.base -fo Re200L1 -Da 1700 -mo Re200L1 -hmax 0.1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re200L1.base -fo Re500L1 -Re 500 -mo Re500L1 -hmax 0.1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re500L1.base -fo Re800L1 -Re 800 -mo Re800L1 -hmax 0.1

ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re200L1.base -fo Re200L0p5 -L 0.5 -mo Re200L0p5 -hmax 0.1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re200L0p5.base -fo Re500L0p5 -Re 500 -mo Re500L0p5 -hmax 0.1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re500L0p5.base -fo Re800L0p5 -Re 800 -mo Re800L0p5 -hmax 0.1

ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re200L1.base -fo Re200L5 -L 5.0 -mo Re200L5 -hmax 0.1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re200L5.base -fo Re500L5 -Re 500 -mo Re500L5 -hmax 0.1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re500L5.base -fo Re800L5 -Re 800 -mo Re800L5 -hmax 0.1
```

### First order
1. Compute the FTFs and forced response fields at St = 1. Note that, according to the settings file, the `-sym` argument activates the acoustic characteristic BC in this setup (it does not influence the modes' symmetry).
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re800L0p5.base -fo Re800L0p5 -mo Re800L0p5 -hmax 0.05
ff-mpirun -np $nproc respcompute.edp -v 0 -dir $workdir -fi Re800L0p5.base -so Re800L0p5 -Rin 0 -Rout -1 -sym 1 -omega 0 -nomega 64 -omegaf 12.6
ff-mpirun -np $nproc respcompute.edp -v 0 -dir $workdir -fi Re800L0p5.base -fo Re800L0p5 -Rin 0 -Rout -1 -sym 1 -omega 6.28318530718 -pv 1

ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re800L1.base -fo Re800L1 -mo Re800L1 -hmax 0.05
ff-mpirun -np $nproc respcompute.edp -v 0 -dir $workdir -fi Re800L1.base -so Re800L1 -Rin 0 -Rout -1 -sym 1 -omega 0 -nomega 64 -omegaf 12.6
ff-mpirun -np $nproc respcompute.edp -v 0 -dir $workdir -fi Re800L1.base -fo Re800L1 -Rin 0 -Rout -1 -sym 1 -omega 6.28318530718 -pv 1

ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re800L5.base -fo Re800L5 -mo Re800L5 -hmax 0.05
ff-mpirun -np $nproc respcompute.edp -v 0 -dir $workdir -fi Re800L5.base -so Re800L5 -Rin 0 -Rout -1 -sym 1 -omega 0 -nomega 64 -omegaf 12.6
ff-mpirun -np $nproc respcompute.edp -v 0 -dir $workdir -fi Re800L5.base -fo Re800L5 -Rin 0 -Rout -1 -sym 1 -omega 6.28318530718 -pv 1
```

2. Compute the eigenspectra at Re = 200, 500, 800 for L = 0.5 for various Rout values.
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re200L0p5.base -fo Re200L0p5 -mo Re200L0p5 -hmax 0.05
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re200L0p5.base -so Re200L0p5 -Rout 0 -sym 1 -eps_target 0.5+6i -eps_nev 50
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re200L0p5.base -so Re200L0p5 -Rout -0.25 -sym 1 -eps_target 0.5+6i -eps_nev 50
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re200L0p5.base -so Re200L0p5 -Rout -0.5 -sym 1 -eps_target 0.5+6i -eps_nev 50
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re200L0p5.base -so Re200L0p5 -Rout -0.75 -sym 1 -eps_target 0.5+6i -eps_nev 50
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re200L0p5.base -so Re200L0p5 -Rout -1 -sym 1 -eps_target 0.5+6i -eps_nev 50

ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi Re500L0p5.base -fo Re500L0p5 -mo Re500L0p5 -hmax 0.05
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re500L0p5.base -so Re500L0p5 -Rout 0 -sym 1 -eps_target 0.5+6i -eps_nev 50
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re500L0p5.base -so Re500L0p5 -Rout -0.25 -sym 1 -eps_target 0.5+6i -eps_nev 50
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re500L0p5.base -so Re500L0p5 -Rout -0.5 -sym 1 -eps_target 0.5+6i -eps_nev 50
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re500L0p5.base -so Re500L0p5 -Rout -0.75 -sym 1 -eps_target 0.5+6i -eps_nev 50
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re500L0p5.base -so Re500L0p5 -Rout -1 -sym 1 -eps_target 0.5+6i -eps_nev 50

ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re800L0p5.base -so Re800L0p5 -Rout 0 -sym 1 -eps_target 0.5+6i -eps_nev 50
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re800L0p5.base -so Re800L0p5 -Rout -0.25 -sym 1 -eps_target 0.5+6i -eps_nev 50
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re800L0p5.base -so Re800L0p5 -Rout -0.5 -sym 1 -eps_target 0.5+6i -eps_nev 50
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re800L0p5.base -so Re800L0p5 -Rout -0.75 -sym 1 -eps_target 0.5+6i -eps_nev 50
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi Re800L0p5.base -so Re800L0p5 -Rout -1 -sym 1 -eps_target 0.5+6i -eps_nev 50
```

3. Perform resolvent analysis at Re = 200, 500, 800 for L = 0.5 for tuned Rout values where sigma ~ -0.45.
```
ff-mpirun -np $nproc rslvcompute.edp -v 0 -dir $workdir -fi Re200L0p5.base -so Re200L0p5 -Rout -0.24125 -sym 1 -omega 0.1 -omegaf 12.5 -nomega 125
ff-mpirun -np $nproc rslvcompute.edp -v 0 -dir $workdir -fi Re500L0p5.base -so Re500L0p5 -Rout -0.70125 -sym 1 -omega 0.1 -omegaf 12.5 -nomega 125
ff-mpirun -np $nproc rslvcompute.edp -v 0 -dir $workdir -fi Re800L0p5.base -so Re800L0p5 -Rout -0.92 -sym 1 -omega 0.1 -omegaf 12.5 -nomega 125
```