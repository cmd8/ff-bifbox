//
// swirljet.geo
// Chris Douglas
// christopher.douglas@duke.edu
//
// This file can be used with Gmsh to create a mesh for the laminar jet as in
// [C. Douglas, B. Emerson, & T. Lieuwen. JFM, (2021)].
//

n0 = 32;
n1 = 8;
n2 = 1;
xmin = -4.0;
rmax = 40.0;
rpipe = 0.5;

// Points
//              3--..,_
//              |      `-.
//              |         `.
//              |           `
//  5-----------4            \
//  |                         |
//  1-----------0-------------2
Point (0)  = {0, 0, 0, 1/n1}; // origin
Point (1)  = {xmin, 0, 0, 1/n1};
Point (2)  = {rmax, 0, 0, 1/n2};
Point (3)  = {0, rmax, 0, 1/n2};
Point (4)  = {0, rpipe, 0, 1/n0};
Point (5)  = {xmin, rpipe, 0, 1/n1};


// Lines
Line (1) = {5,1};
Line (2) = {1,2};
Circle (3) = {2,0,3};
Line (4) = {3,4};
Line (5) = {4,5};

// Labels
Physical Line ("AXIS") = {2};
Physical Line ("OUTFLOW") = {3};
Physical Line ("INFLOW") = {1};
Physical Line ("WALL") = {4};
Physical Line ("PIPE") = {5};

// Surfaces
Line Loop(1) = {1:5};
Plane Surface(1) = {1};
Physical Surface("DOMAIN") = {1};
