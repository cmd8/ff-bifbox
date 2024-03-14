//
// cavity.geo
// Chris Douglas
// cdoug@mit.edu
//
// This file can be used with Gmsh to create a mesh for the cavity as in
// [D. Sipp and A. Lebedev, JFM (2007) DOI:10.1017/S0022112007008907].
//

n0 = 20;
n1 = 10;
n2 = 1;
t = 1.0/6.0;
W = 1.0;
L = 2.5;
xmin = -10.0;
xmax = 25.0;
ymax = 7.0;
zmax = 15.0;
Mesh.Algorithm = 5;
Mesh.Format = 1;
Mesh.MshFileVersion = 2.2;
Mesh.SaveAll = 0;

Point (1)  = {xmin, 0, 0, 1/n2};
Point (2)  = {xmin, ymax, 0, 1/n2};
Point (3)  = {xmax, ymax, 0, 1/n2};
Point (4)  = {xmax, 0, 0, 1/n1};
Point (5)  = {t/2, 0, 0, 1/n0};
Point (6)  = {t/2, W/2, 0, 1/n0};
Point (7)  = {-t/2, W/2, 0, 1/n0};
Point (8)  = {-t/2, 0, 0, 1/n0};
Point (9)  = {-t/2, 0, L/2, 1/n0};
Point (10)  = {-t/2, W/2, L/2, 1/n0};
Point (11)  = {t/2, W/2, L/2, 1/n0};
Point (12)  = {t/2, 0, L/2, 1/n0};
Point (13)  = {xmin, 0, zmax, 1/n2};
Point (14)  = {xmin, ymax, zmax, 1/n2};
Point (15)  = {xmax, ymax, zmax, 1/n2};
Point (16)  = {xmax, 0, zmax, 1/n2};


// Lines
Line (1) = {8,1};
For ii In {2:8}
Line (ii) = {ii-1, ii};
EndFor
For ii In {9:12}
Line (ii) = {ii-1, ii};
EndFor
Line (13) = {7,10};
Line (14) = {6,11};
Line (15) = {5,12};
Line (16) = {9,12};
Line (19) = {1,13};
Line (20) = {2,14};
Line (21) = {3,15};
Line (22) = {4,16};
Line (23) = {13,14};
Line (24) = {14,15};
Line (25) = {15,16};
Line (26) = {16,13};

// Surfaces
Line Loop(1) = {1:8};
Plane Surface(1) = {1};
Line Loop(2) = {8, 9, 10, -13};
Plane Surface(2) = {2};
Line Loop(3) = {11, -14, 7, 13};
Plane Surface(3) = {3};
Line Loop(4) = {12, -15, 6, 14};
Plane Surface(4) = {4};
Line Loop(5) = {16, -12, -11, -10};
Plane Surface(5) = {5};
Line Loop(6) = {5, 15, -16, -9, 1, 19, -26, -22};
Plane Surface(6) = {6};
Line Loop(7) = {4, 22, -25, -21};
Plane Surface(7) = {7};
Line Loop(8) = {21, -24, -20, 3};
Plane Surface(8) = {8};
Line Loop(9) = {23, -20, -2, 19};
Plane Surface(9) = {9};
Line Loop(10) = {23:26};
Plane Surface(10) = {10};


// Volumes
Surface Loop(1) = {1:10};
Volume(1) = {1};

// Labels
Physical Surface ("WALL") = {2:5};
Physical Surface ("INLET") = {9};
Physical Surface ("LATERAL1") = {8};
Physical Surface ("LATERAL2") = {10};
Physical Surface ("OPEN") = {7};
Physical Surface ("AXIS1") = {6};
Physical Surface ("AXIS2") = {1};
Physical Volume ("DOMAIN")  = {1};