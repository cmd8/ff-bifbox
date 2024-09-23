//
// Vflame.geo
// Chris Douglas
// christopher.douglas@duke.edu
//
// This file can be used with Gmsh to create a mesh for the annular V-flame configuration.
//

n0 = 12500;
n1 = 3125;
n2 = 2500;
n3 = 1250;
n4 = 500;

xmin = -0.03;
xmax = 0.20;
rmax = 0.05;
D = 0.011;
Dcb = 0.003;
xcb = 0.002;

right_end = 0.038;
up_in = 0.008;
up_cb = 0.010;
up_middle = 0.025;
up_end = 0.035;
left_in = -0.005;
x1 = 0.06;
r1 = 0.04;

// Points
//             22----------------------------------------21
//              |                                        |
//             19-------------------18                   |
//              |                   |                    |
//              9-----------11      |                    |
//              |           |       |                    |
//              | ----------12      |                    |
//              |/          |       |                    |
//              8           |       |                    |
//              |           |       |                    |
//  4-----------7           |       |                    |
//  |                       |       |                    |
//  |           ------------15      |                    |
//  |          /            |       |                    |
//  |         /      -------16      |                    |
//  3--------14---2 /       |       |                    |
//                |/        |       |                    |
//              o 1---------13------17-------------------20
Point(1) = {xcb, 0, 0, 1/n0};
Point(2) = {xcb, 0.5*Dcb, 0, 1/n0};
Point(3) = {xmin, 0.5*Dcb, 0, 1/n2};
Point(4) = {xmin, 0.5*D, 0, 1/n2};
Point(7) = {0, 0.5*D, 0, 1/n2};
Point(8) = {0, up_in, 0, 1/n2};
Point(9) = {0, up_end, 0, 1/n2};
Point(11) = {right_end, up_end, 0, 1/n2};
Point(12) = {right_end, up_middle, 0, 1/n1};
Point(13) = {right_end, 0, 0, 1/n2};
Point(14) = {left_in, 0.5*Dcb, 0, 1/n0};
Point(15) = {right_end, up_cb+up_in, 0, 1/n0};
Point(16) = {right_end, up_cb, 0, 1/n0};
Point(17) = {x1, 0, 0, 1/n3};
Point(18) = {x1, r1, 0, 1/n3};
Point(19) = {0, r1, 0, 1/n3};
Point(20) = {xmax, 0, 0, 1/n4};
Point(21) = {xmax, rmax, 0, 1/n4};
Point(22) = {0, rmax, 0, 1/n4};

// Lines
Line(1) = {3, 14};
Line(2) = {14, 2};
Line(3) = {2, 1};
Line(4) = {1, 13};
Line(5) = {13, 16};
Line(6) = {16, 15};
Line(7) = {15, 12};
Line(8) = {12, 11};
Line(9) = {11, 9};
Line(10) = {9, 8};
Line(11) = {8, 7};
Line(12) = {7, 4};
Line(13) = {4, 3};
Line(15) = {14, 15};
Line(16) = {1, 16};
Line(17) = {12, 8};
Line(18) = {19, 9};
Line(19) = {13, 17};
Line(20) = {17, 18};
Line(21) = {18, 19};
Line(22) = {19, 22};
Line(23) = {22, 21};
Line(24) = {21, 20};
Line(25) = {20, 17};

// Labels
Physical Line("axis") = {4, 19, 25};
Physical Line("outlet") = {24};
Physical Line("lateral") = {23};
Physical Line("planewall") = {10, 11, 18, 22};
Physical Line("annuluswall") = {1, 2, 12};
Physical Line("inlet") = {13};
Physical Line("centerbodywall") = {3};

// Surfaces
Line Loop(1) = {-23, -24, -25, 19, 4, 3, 2, 1, 13, 12, 11, 10, 18, -22};
Plane Surface(1) = {1};
Line {5:9,15:17,20:21} In Surface{1};
Physical Surface("DOMAIN") = {1};