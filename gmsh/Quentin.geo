// ANNULARJETMESH GEOMETRY FILE
n0 = 64;
n1 = 16;
n2 = 4;
lin = 1.0;
lout = 34.0;
R = 1.0;
h = 1.0e-5;
rout = 6.0;
Mesh.Algorithm = 5;
Mesh.MshFileVersion = 2.2;
Mesh.SaveAll = 0;

// origin
Point (1)  = {-lin, 0, 0, 1/n1};
Point (2)  = {lout, 0, 0, 1/n2};
Point (3)  = {lout, rout, 0, 1/n2};
Point (4)  = {-lin, rout, 0, 1/n2};
Point (5)  = {-lin, R+h, 0, 1/n1};
Point (6)  = {0, R+h, 0, 1/n1};
Point (7)  = {0, R, 0, 1/n0};
Point (8)  = {-lin, R, 0, 1/n1};

// Boundary lines
Line (1) = {8,1};
For ii In {2:8}
Line (ii) = {ii-1, ii};
EndFor

// Physical Lines
Physical Line ("AXIS") = {2};
Physical Line ("OPEN") = {3,4};
Physical Line ("IN2") = {5};
Physical Line ("WALL") = {6:8};
Physical Line ("IN1") = {1};

// Surfaces
Line Loop(1) = {1:8};
Plane Surface(1) = {1};
Physical Surface("DOMAIN") = {1};
