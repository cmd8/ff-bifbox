//
// cylinder.geo
// Chris Douglas
// chris.douglas@ladhyx.polytechnique.fr
//
// This file can be used with Gmsh to create a mesh for the cylinder.
//

n0 = 25;
n1 = 2.5;
n2 = 0.25;
xmin = -60.0;
xmax = 120.0;
rmax = 30.0;
rcyl = 0.5;
Mesh.Algorithm = 5;
Mesh.MshFileVersion = 2.2;
Mesh.SaveAll = 0;

// Points
//  4--------------------------------------3
//  |                                      |
//  |                                      |
//  |           ╭--3--╮                    |
//  |           2  0  4                    |
//  |           ╰--3--╯                    |
//  |                                      |
//  |                                      |
//  1--------------------------------------2
Point (0)  = {0, 0, 0, 1/n0}; // origin
Point (1)  = {xmin, -rmax, 0, 1/n2};
Point (2)  = {xmax, -rmax, 0, 1/n2};
Point (3)  = {xmax, rmax, 0, 1/n2};
Point (4)  = {xmin, rmax, 0, 1/n2};
Point (5)  = {-rcyl, 0, 0, 1/n0};
Point (6)  = {rcyl, 0, 0, 1/n0};

// Lines
Line (1) = {4,1};
Line (2) = {1,2};
Line (3) = {2,3};
Line (4) = {3,4};
Circle (5) = {5,0,6};
Circle (6) = {6,0,5};
// Labels
Physical Line ("AXIS") = {};
Physical Line ("OUTFLOW") = {3};
Physical Line ("INFLOW") = {1};
Physical Line ("WALL") = {5,6};
Physical Line ("SLIP") = {2,4};

// Surfaces
Line Loop(1) = {1:4};
Line Loop(2) = {5:6};
Plane Surface(1) = {1,2};
Physical Surface("DOMAIN") = {1};
