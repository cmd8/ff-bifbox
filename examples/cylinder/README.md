# Cylinder example
This file shows an example `ff-bifbox` workflow for a stability/bifurcation analysis of the incompressible flow over a 2D cylinder.

## Problem setup
### Navigate to the main `ff-bifbox` directory

### Build mesh
#### CASE 1: Gmsh is installed - build directly from .geo file
```
mpirun -n 1 FreeFem++-mpi -v 0 importgmsh.edp -dir examples/cylinder/ -mi cylinder.geo -mo cylinder
```
#### CASE 2: Gmsh is not installed
```
mpirun -n 1 FreeFem++-mpi -v 0 examples/cylinder/cylinder.edp -mo cylinder
```

### Create symbolic links
```
ln -sf examples/cylinder/eqns_cylinder.idp eqns.idp
ln -sf examples/cylinder/settings_cylinder.idp settings.idp
```

## Find Hopf bifurcation
### Compute base state on the created mesh at Re = 10 from default guess
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir examples/cylinder/ -mi cylinder.msh -fo cylinder10 -1/Re 0.1
```

### Continue base state along the parameter 1/Re with adaptive remeshing
```
mpirun -n 4 FreeFem++-mpi -v 0 basecontinue.edp -dir examples/cylinder/ -fi cylinder10.base -fo cylinderRe -param 1/Re -h0 -1 -dmax 10 -scount 2 -maxcount 8 -mo cylinderRe
```

### Compute base state at Re = 50 with guess from continuation
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir examples/cylinder/ -fi cylinderRe_8.base -fo cylinder50 -1/Re 0.02
```

### Adapt mesh to the solution at Re = 50
```
mpirun -n 4 FreeFem++-mpi -v 0 basecompute.edp -dir examples/cylinder/ -fi cylinder50.base -fo cylinder50adapted -mo cylinder50adapted
```

### Compute leading direct eigenmode at Re = 50
```
mpirun -n 4 FreeFem++-mpi -v 0 modecompute.edp -dir examples/cylinder/ -fi cylinder50adapted.base -fo cylinder50adapted -eps_target 0.1+0.8i -sym 1
```

### Compute the critical point and critical base/direct/adjoint solution
```
mpirun -n 4 FreeFem++-mpi -v 0 hopfcompute.edp -dir examples/cylinder/ -fi cylinder50adapted_0.mode -fo BVK -param 1/Re
```

### Adapt the mesh to the critical solution, save .vtu files for Paraview
```
mpirun -n 4 FreeFem++-mpi -v 0 hopfcompute.edp -dir examples/cylinder/ -fi BVK.hopf -fo BVKadapted -mo BVKadapted -adaptto bda -param 1/Re -pv 2
```
