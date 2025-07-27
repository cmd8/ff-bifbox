# Low-Mach conical flame Example: Douglas et al., CnF, (2023)
This file shows an example `ff-bifbox` workflow for reproducing the results in the study:
```tex
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
```sh
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory and number of processors for easy reference.
```sh
export workdir=examples/douglas_etal_2023/data
export nproc=4
```
3. Create symbolic links for governing equations and solver settings.
```sh
ln -sf examples/douglas_etal_2023/eqns_douglas_etal_2023.idp eqns.idp
ln -sf examples/douglas_etal_2023/settings_douglas_etal_2023.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from `.geo` files
```sh
FreeFem++-mpi -v 0 importgmsh.edp -gmshdir examples/douglas_etal_2023 -dir $workdir -mi jet.geo
```
Note: since no `-mo` argument is specified, the output files (`.msh`) inherit the names of their parents (`.geo`).
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```sh
FreeFem++-mpi -v 0 examples/douglas_etal_2023/jet.edp -mo $workdir/jet
```

## Perform parallel computations using `ff-bifbox`
1. Compute a base state on the created mesh at $Re=10$, $Pr=0.7$, $Le=1$, $Da=1$, $dT=4$, $Ze=0$, $a=2/3$.
```sh
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -mi jet.msh -fo ignite_0 -Re 10 -Pr 0.7 -Le 1 -Da 1 -dT 4 -Ze 0 -a 0.6666666666666667
```

2. Increase $Re$ to $1000$ with adaptive remeshing.
```sh
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_0.base -fo ignite_1 -Re 50
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_1.base -fo ignite_2 -Re 120
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_2.base -fo ignite_3 -Re 300
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_3.base -fo ignite_4 -Re 700
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_4.base -fo ignite_5 -Re 1000 -mo ignite_5
```

2. Gradually ignite the conical flame via continuation of $Da$ and $Ze$ and timestepping. (slow!)
```sh
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_5.base -fo ignite_6 -Da 3 -Ze 1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_6.base -fo ignite_7 -Da 7 -Ze 1.3
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_7.base -fo ignite_8 -Da 16 -Ze 1.5
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_8.base -fo ignite_9 -Da 30 -Ze 1.65
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_9.base -fo ignite_10 -Da 45 -Ze 1.75 -mo ignite_10
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_10.base -fo ignite_11 -Da 55 -Ze 1.8
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_11.base -fo ignite_12 -Da 67 -Ze 1.85 -mo ignite_12
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_12.base -fo ignite_13 -Da 82 -Ze 1.9
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_13.base -fo ignite_14 -Da 102 -Ze 1.95 -mo ignite_14
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_14.base -fo ignite_15 -Da 126 -Ze 2 -mo ignite_15
ff-mpirun -np $nproc tdnscompute.edp -v 0 -dir $workdir -fi ignite_15.base -fo ignitetime -Le 0.7 -Ze 10 -Da 5000 -ts_dt 0.0025 -mo ignitetime -scount 5 -maxcount 120 -pv 1 -ts_adapt_type basic -ts_atol 1e10
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignitetime_120.tdns -fo conicalflame -mo conicalflame
```

3. Compute the $|m|=11$ polyhedral flame bifurcation at $Da=4000$, $Le\sim0.845$.
```sh
ff-mpirun -np $nproc tdnscompute.edp -v 0 -dir $workdir -fi conicalflame.base -fo polyhedral -Le 0.845 -Da 4000 -ts_dt 0.0025 -mo polyhedral -scount 5 -maxcount 25 -ts_adapt_type basic -ts_atol 1e10
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi polyhedral_25.tdns -fo polyhedral -mo polyhedral
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi polyhedral.base -fo polyhedral -sym 11 -eps_target 0.1+0i
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi polyhedral.mode -fo polyhedral -param Le -nf 0 -zero 1
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi polyhedral.hopf -fo polyhedral -mo polyhedralm11 -adaptto bda -param Le -zero 1 -pv 1
```

4. Compute the $|m|=1$ tilted flame bifurcation at $Le=1.1$, $Da\sim9130$.
```sh
ff-mpirun -np $nproc tdnscompute.edp -v 0 -dir $workdir -fi conicalflame.base -fo tilted -Le 1.1 -Da 9135 -ts_dt 0.0025 -mo tilted -scount 5 -maxcount 150 -ts_adapt_type basic -ts_atol 1e10
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi tilted_150.tdns -fo tilted -mo tilted
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi tilted.base -fo tilted -sym 1 -eps_target 0.1+0i
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi tilted.mode -fo tilted -param Da -zero 1 -nf 0 -snes_divergence_tolerance 1e8
ff-mpirun -np $nproc hopfcompute.edp -v 0 -dir $workdir -fi tilted.hopf -fo tilted -mo tiltedm1 -adaptto bda -param Da -zero 1 -pv 1
```

5. Continue the base flow along $Le$ at $Da=4000$. (slow!)
```sh
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi polyhedral.base -fo Da4000Leup -mo Da4000Leup -param Le -h0 10 -scount 5 -maxcount 200
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi polyhedral.base -fo Da4000Ledown -mo Da4000Ledown -param Le -h0 -10 -scount 5 -maxcount 400
```

6. Continue the base flow along $Da$ at $Le=1$. (very slow!)
```sh
ff-mpirun -np $nproc tdnscompute.edp -v 0 -dir $workdir -fi conicalflame.base -fo conicalflame -Le 1 -Da 4000 -ts_dt 0.0025 -mo conicalflame -scount 5 -maxcount 60 -pv 1 -ts_adapt_type basic -ts_atol 1e10
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi conicalflame_60.tdns -fo Le1Da4000 -mo Le1Da4000
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi Le1Da4000.base -fo Le1Daup -mo Le1Daup -param Da -h0 10 -scount 5 -maxcount 1000
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi Le1Da4000.base -fo Le1Dadown -mo Le1Dadown -param Da -h0 -10 -scount 5 -maxcount 500
```
