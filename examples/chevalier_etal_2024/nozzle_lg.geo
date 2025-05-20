//
// nozzle_lg.geo
// Chris Douglas
// christopher.douglas@duke.edu
//
// This file can be used with Gmsh to create a mesh for the turbulent swirling jet as in
// [Chevalier et al, TCFD, (2024)].
//
// This file is adapted from Quentin Chevalier's geometry found at
// https://github.com/hawkspar/openfoam/blob/main/nozzle/nozzle.geo
R = 1;
L = 60*R;
H = 20*R;
r = 1.2e-3;
w = 0.05;
h = 1.0e-4;
hh = 1.0e-5;

// Base 'rectangle'
Point(1) = {-R, 0, 0,   50*r};
Point(2) = {L-R, 0, 0,  200*r};
Point(3) = {L-R, H, 0,  750*r};
Point(4) = {-R, H, 0, 1000*r};
// Actual nozzle
Point(5) = {-R, R,   0, r};
Point(6) = {-R, R+h, 0, r};
Point(60) = {0, R+hh,   0, r};
Point(7) = {0, R,   0, r};
// Most refined area
Point(8)  = {-w*R,      R,   0, r};
Point(9)  = {-w*R,      R+h, 0, r};
Point(10) = {-w*R,  .99*R,   0, r};
Point(11) = {0.1*R,  .99*R,   0, r};
Point(12) = {0.1*R, 1.01*R,   0, r};
Point(13) = {-w*R, 1.01*R,   0, r};
// Less refined area
Point(14) = {-0.1*R,      R,   0,   r};
Point(15) = {-0.1*R,      R+h, 0,   r};
Point(16) = {-0.1*R,   .9*R,   0, 4*r};
Point(17) = { R,   .9*R,   0, 5*r};
Point(18) = { R,  1.2*R,   0, 7*r};
Point(19) = {-0.1*R, 1.05*R,   0, 7*r};
// Less refined area 2
Point(20) = {-0.15*R,     R,   0,     r};
Point(21) = {-0.15*R,     R+h, 0,     r};
Point(22) = {-0.15*R, .85*R,   0,   7*r};
Point(23) = { 34*R,  .3*R,   0, 125*r};
Point(24) = { 49*R,  19*R,   0, 300*r};
Point(25) = {-0.15*R,   2*R,   0,  75*r};

// Main rectangle
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 6};
Line(5) = {5, 1};
// Nozzle
Line(6)  = {6,  21};
Line(7)  = {21, 15};
Line(8)  = {15,  9};
Line(9)  = {9,  60};
Line(90) = {60,  7};
Line(10) = {7,   8};
Line(11) = {8,  14};
Line(12) = {14, 20};
Line(13) = {20,  5};
// Outer zone
Line(14) = {21, 25};
Line(15) = {25, 24};
Line(16) = {24, 23};
Line(17) = {23, 22};
Line(18) = {22, 20};
// Middle zone
Line(19) = {15, 19};
Line(20) = {19, 18};
Line(21) = {18, 17};
Line(22) = {17, 16};
Line(23) = {16, 14};
// Inner zone
Line(24) = {9,  13};
Line(25) = {13, 12};
Line(26) = {12, 11};
Line(27) = {11, 10};
Line(28) = {10,  8};

// Physical Lines
Physical Line ("AXIS") = {1};
Physical Line ("OPEN") = {2};
Physical Line ("LAT") = {3};
Physical Line ("IN2") = {4};
Physical Line ("WALL") = {6:9,90,10:13};
Physical Line ("IN1") = {5};

// Surfaces
Line Loop(1) = {1:4,6:9,90,10:13,5};
Plane Surface(1) = {1};
Line {14:28} In Surface{1};

Physical Surface("DOMAIN") = {1};
