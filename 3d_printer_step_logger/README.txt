
This tool allows an ICEStick to count steps from a 3D printer,
generating a log of a printer's motion for post-analysis.

The STEP and DIR lines for X, Y, Z and E are wired into the PMOD
connector as follows:

    step_x --> PMOD Left Row 1
    step_y --> PMOD Left Row 2
    step_z --> PMOD Left Row 3
    step_e --> PMOD Left Row 4

    dir_x  --> PMOD Right Row 7
    dir_y  --> PMOD Right Row 8
    dir_z  --> PMOD Right Row 9
    dir_e  --> PMOD Right Row 10

Then, use a terminal program to connect to the ICEstick at 9600.
A stream of hex numbers will be printed to the console. The numbers
are a concatenation of the step counts for the X, Y, Z and E axis.
By default, it consists of the following format:

    XXXXYYYYZZZZZEEEEE

The number of nibbles (hex digits) per counter determines how many
steps can be counted per axis. This can be controlled by the following
parameters in top.v:

    parameter x_nibbles = 4;
    parameter y_nibbles = 4;
    parameter z_nibbles = 5;
    parameter e_nibbles = 5;

For analysis, the log file must be loaded, broken up into X, Y, Z and E,
fields and converted from hex to decimal. "show_data.m" is an Octave
script that shows how this may be done.



(c) 2017 Aleph Objects, Inc.
Licensed under GNU GPL v3
