//
// nozzle_sm.geo
// Chris Douglas
// christopher.douglas@duke.edu
//
// This file can be used with Gmsh to create a mesh for the turbulent swirling jet as in
// [Chevalier et al, TCFD, (2024)].
//
// This file is adapted from Quentin Chevalier's geometry found at
// https://github.com/hawkspar/openfoam/blob/main/nozzle/nozzle.geo
R = 1;
L = 50*R;
H = 15*R;
r = 1.2e-3;
w = 0.05;
h = 1.0e-4;
hh = 1.0e-5;

// First base rectangle around the nozzle
Point(1) = {-R, 0, 0,   30*r};
Point(2) = {0, 0, 0,   20*r};
Point(3) = {0, H, 0, 1000*r};
Point(4) = {-R, H, 0, 1000*r};
// Second (largest) base rectangle
Point(5) = {L-R, 0, 0, 250*r};
Point(6) = {L-R, H, 0, 750*r};
// Actual nozzle
Point(9)  = {-R, R,   0, r};
Point(10) = {-R, R+h, 0, r};
Point(110) = {0, R+hh,   0, r};
Point(11) = {0, R,   0, r};
// Most refined area (left)
Point(12) = {-w*R,      R,   0, r};
Point(13) = {-w*R,  .99*R,   0, r};
Point(14) = {	 0,  .99*R,   0, r};
Point(15) = {	 0, 1.01*R,   0, r};
Point(16) = {-w*R, 1.01*R,   0, r};
Point(17) = {-w*R,      R+h, 0, r};
// Most refined area (center)
Point(18) = {0.1*R,  .99*R,   0, r};
Point(19) = {0.1*R, 1.01*R,   0, r};
// Less refined area (left)
Point(20) = {-0.7*R,     R,   0,     r};
Point(21) = {-0.7*R,  .7*R,   0,  10*r};
Point(22) = {	0,  .7*R,   0,  10*r};
Point(23) = {	0, 1.1*R,   0,  10*r};
Point(24) = {-0.7*R, 1.1*R,   0,  10*r};
Point(25) = {-0.7*R,     R+h, 0,     r};
// Less refined area (center)
Point(26) = {29*R, .25*R, 0, 200*r};
Point(27) = {44*R,  14*R, 0, 300*r};

// Largest Loop
Line(1)  = {1,  2};
Line(2)  = {2,  5};
Line(6)  = {6,  3};
Line(7)  = {3,  4};
Line(8)  = {4, 10};
Line(9)  = {10,25};
Line(10) = {25,24};
Line(11) = {24,23};
Line(12) = {23,27};
Line(13) = {27,26};
Line(14) = {26,22};
Line(15) = {22,21};
Line(16) = {21,20};
Line(17) = {20, 9};
Line(18) = {9,  1};
// Smaller Loop
Line(19) = {20,12};
Line(20) = {12,13};
Line(21) = {13,14};
Line(22) = {14,18};
Line(23) = {18,19};
Line(24) = {19,15};
Line(25) = {15,16};
Line(26) = {16,17};
Line(27) = {17,25};
// Tiny Loop
Line(28) = {17,110};
Line(280) = {110,11};
Line(29) = {11,12};
// Verticals
Line(30) = {2, 22};
Line(31) = {22,14};
Line(32) = {14,11};
Line(33) = {110,15};
Line(34) = {15,23};
Line(35) = {23, 3};
Line(36) = {5, 6};

// Physical Lines
Physical Line ("AXIS") = {1,2};
Physical Line ("OPEN") = {36};
Physical Line ("LAT") = {6,7};
Physical Line ("IN2") = {8};
Physical Line ("WALL") = {9,17,27,19,28,29,280};
Physical Line ("IN1") = {18};

// Surfaces
Line Loop(1) = {1,2,36,6,7,8,9,-27,28,280,29,-19,17,18};
Plane Surface(1) = {1};
Line {10:16,20:26,30:35} In Surface{1};

Physical Surface("DOMAIN") = {1};
