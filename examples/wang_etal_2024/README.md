# Low-Mach V-flame Example: Wang et al., JFM, (2024)
This file shows an example `ff-bifbox` workflow for reproducing the results in the study:
```
@article{wang_etal_2024,
  title = {{Onset of global instability in a premixed annular V-flame}},
  author = {Wang, Chuhan and Douglas, Christopher M. and Guan, Yu and Xu, Chunxiao and Lesshafft, Lutz},
  journal={Journal of Fluid Mechanics},
  publisher={Cambridge University Press},
  volume={998},
  pages={A23}
  year={2024},
  DOI={10.1017/jfm.2024.869},
}
```
The commands below illustrate how to perform a bifurcation analysis of a lean premixed V-flame in an axisymmetric annular jet using `ff-bifbox`.

## Setup environment for `ff-bifbox`
1. Navigate to the main `ff-bifbox` directory.
```
cd ~/your/path/to/ff-bifbox/
```
2. Export working directory and number of processors for easy reference.
```
export workdir=examples/wang_etal_2024/data
export nproc=4
```
3. Create symbolic links for governing equations and solver settings.
```
ln -sf examples/wang_etal_2024/eqns_wang_etal_2024.idp eqns.idp
ln -sf examples/wang_etal_2024/settings_wang_etal_2024.idp settings.idp
```

## Build initial meshes
`ff-bifbox` uses FreeFEM for adaptive meshing during the solution process, but it needs an initial mesh to adaptively refine.
#### CASE 1: Gmsh is installed - build initial mesh directly from `.geo` files
```
FreeFem++-mpi -v 0 importgmsh.edp -gmshdir examples/wang_etal_2024 -dir $workdir -mi Vflame.geo
```
Note: since no `-mo` argument is specified, the output files (`.msh`) inherit the names of their parents (`.geo`).
#### CASE 2: Gmsh is not installed - build initial mesh using BAMG in FreeFEM
```
FreeFem++-mpi -v 0 examples/wang_etal_2024/Vflame.edp -mo $workdir/Vflame
```

## Perform parallel computations using `ff-bifbox`
Note that, unlike most of the `ff-bifbox` examples, the results in `wang_etal_2024` are reported in dimensional variables. While non-dimensionalization is preferable for better numerical scaling, the SI units used in the study are retained here for the sake of example.
### Laminar base flow
1. Compute a non-reacting base state with reference parameters on the initial mesh.
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir examples/wang_etal_2024/data -mi Vflame.msh -fo nonreacting_0 -U0 0.1 -Tr 700 -As 1.67212e-6 -Ts 170.672 -Pr 0.7 -Sc 0.7 -p0 101325 -Rs 264.56013215560904 -Cp 1.3 -YCH4 0.04256 -WCH4 0.016 -YO2 0.2128 -WO2 0.032 -nCH4 1.0 -nO2 0.5 -Ar 0 -Ta 10065.425264217412 -Dh0f -804.084 -alpha 0.05 -xsg 0.15 -rsg 0.03 -snes_rtol 0
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi nonreacting_0.base -fo nonreacting_1 -U0 0.5 -mo nonreacting_1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi nonreacting_1.base -fo nonreacting -U0 2.2 -pv 1 -mo nonreacting
```

2. Turn on chemistry and ignite the $U_0=2.2$ m/s flow at an elevated centrebody temperature and lower combustion enthalpy. Then perform continuation back to reference parameters. Coarse meshes are used for computational efficiency and stabilizing artificial dissipation. 
```
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi nonreacting.base -fo ignite_0 -Tr 1000 -Ar 1.1e7 -Dh0f -100 -mo ignite_0 -snes_rtol 0 -err 0.05
ff-mpirun -np $nproc basecontinue.edp -v 0 -dir $workdir -fi ignite_0.base -fo ignite -param Dh0f -h0 -200 -mo ignite -dmax 100 -err 0.1 -scount 5 -paramtarget -804.084 -maxcount -1 -contorder 2
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignite_335.base -fo ignited -Tr 700 -Dh0f -804.084 -mo ignited -snes_rtol 0 -err 0.05 -snes_linesearch_type l2
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi ignited.base -fo U02p2 -pv 1 -snes_rtol 0 -snes_linesearch_type l2 -mo U02p2
```

3. Save base flows in 0.1 m/s increments for $U_0=2.3$ m/s to $U_0=3.8$ m/s. Dissipation from mesh coarsening is used to aid convergence at each step before refining the coarse solutions on the reference mesh.
```
for i in {3..9}
do
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi "U02p$(($i-1))".base -fo U0inc -U0 2."$i" -snes_linesearch_type l2 -mo U0inc -err 0.1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi U0inc.base -fo U02p"$i" -pv 1 -snes_rtol 0 -snes_linesearch_type l2 -mo U02p"$i"
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi U02p"$i".base -fo U02p"$i" -pv 1 -snes_rtol 0 -snes_linesearch_type l2 -mo U02p"$i"
done
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi U02p9.base -fo U0inc -U0 3.0 -snes_linesearch_type l2 -mo U0inc -err 0.1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi U0inc.base -fo U03p0 -pv 1 -snes_rtol 0 -mo U03p0
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi U03p0.base -fo U03p0 -pv 1 -snes_rtol 0 -mo U03p0
for i in {1..8}
do
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi "U03p$(($i-1))".base -fo U0inc -U0 3."$i" -snes_linesearch_type l2 -mo U0inc -err 0.1
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi U0inc.base -fo U03p"$i" -pv 1 -snes_rtol 0 -snes_linesearch_type l2
ff-mpirun -np $nproc basecompute.edp -v 0 -dir $workdir -fi U03p"$i".base -fo U03p"$i" -pv 1 -snes_rtol 0 -snes_linesearch_type l2 -mo U03p"$i"
done
```

### Global linear analysis
4. Compute global eigenspectra at $Re=1978$, $Re=2282$, $Re=2586$, and $Re=2891$. Notably, unlike in the paper, the present results do not identify any criticality of the leading flame-tip eigenmode at $Re=2815$. The source of this disagreement is not known. 
```
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi U02p6.base -so Re1978 -eps_nev 25 -eps_target 25+250i -ntarget 8 -targetf 50+2000i
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi U03p0.base -so Re2282 -eps_nev 25 -eps_target 25+250i -ntarget 8 -targetf 50+2000i
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi U03p4.base -so Re2586 -eps_nev 25 -eps_target 25+250i -ntarget 8 -targetf 50+2000i
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi U03p8.base -so Re2891 -eps_nev 25 -eps_target 25+250i -ntarget 8 -targetf 50+2000i
```
5. Compute leading flame-tip eigenmode at $Re=2282$ 
```
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi U03p0.base -fo Re2282flametip -eps_target 1+600i -pv 1
```

6. Compute optimal gain curve in velocity 2-norm at $Re=2282$ and $Re=2586$.
```
ff-mpirun -np $nproc rslvcompute.edp -v 0 -dir $workdir -fi U03p0.base -so Re2282 -omega 20 -omegaf 2000 -nomega 100
ff-mpirun -np $nproc rslvcompute.edp -v 0 -dir $workdir -fi U03p4.base -so Re2586 -omega 20 -omegaf 2000 -nomega 100
```

7. Compute optimal response at $Re=2586$ for $St=0.31$ and $St=0.68$.
```
ff-mpirun -np $nproc rslvcompute.edp -v 0 -dir $workdir -fi U03p4.base -fo Re2586St0p31 -omega 602 -pv 1
ff-mpirun -np $nproc rslvcompute.edp -v 0 -dir $workdir -fi U03p4.base -fo Re2586St0p68 -omega 1320 -pv 1
```

### Nonlinear analysis
8. Compute nonlinear dynamics at $Re=1978$ in time domain. Here, the maximum velocity magnitude of the eigenmode and the base flow are rescaled to provide initial velocity perturbation amplitudes that correspond to the 20% and 50% amplitudes used in the paper. Nonetheless, since the phase was not explicitly specified, variations in the initial phase may cause these results to differ qualitatively from those in the paper.
```
ff-mpirun -np $nproc modecompute.edp -v 0 -dir $workdir -fi U02p6.base -fo Re1978flametip -eps_target 1+600i -pv 1
ff-mpirun -np 1 examples/wang_etal_2024/moderescale.edp -v 0 -dir $workdir -fi Re1978flametip.mode -fo Re1978flametip_scaled
ff-mpirun -np $nproc tdnscompute.edp -v 0 -dir $workdir -bfi U02p6.base -fi Re1978flametip_scaled.mode -fo Re1978perturbation20perc -amp 0.2 -ts_dt 0.0001 -ts_adapt none -scount 2 -maxcount 6000 -mo Re1978perturbation20perc
ff-mpirun -np $nproc tdnscompute.edp -v 0 -dir $workdir -bfi U02p6.base -fi Re1978flametip_scaled.mode -fo Re1978perturbation50perc -amp 0.5 -ts_dt 0.0001 -ts_adapt none -scount 2 -maxcount 6000 -mo Re1978perturbation50perc
```