// parametric pen ball - scruss 2018-03
// CC BY-SA - Stewart Russell - scruss.com
// for Makers Making Change - http://makersmakingchange.com/

// you will need:
// * 5 off M4 x 12 stainless pan head machine screws
// * 5 off M4 stainless nuts

// ** the two main parameters **
// may produce a useless design, so change at your own risk
ball_diam = 60.0;   // 60 mm is default; can go to 45 if wall_thick reduced
pen_diam = 10.5;    // should fit most pens; 10.5 mm is default

// ** lesser parameters
wall_thick = 2.0;   // shell thickness; default 2, reduce to 1 for 45 mm diameter
tol=0.8;            // tolerance for loose fit
// *** NB: please do not explicitly set $fn ***
// and everything below here: HERE BE (smallish) DRAGONS

/* M4 nut and screw dimensions - sized for M4 x 12

Nut: 7 mm across flats, 3.2 mm thick
so across points = 7 / ((√3) / 2) ~= 8.1 mm
source: http://www.fairburyfastener.com/xdims_metric_nuts.htm

Screw:          4.0 mm, 4.7 to outside of thread
Length:        12 or 20 mm
Head height:    3.1 mm
Head diameter:  8.0 mm
source: https://spaenaur.com/pdf/sectionR/R11.pdf
*/
nut_thick =          3.2;
nut_flats =          7.0;
nut_diam =          nut_flats / (sqrt(3)/2);
screw_length =      12.0;            // M4 x 12
screw_nom_diam =     4.0;
screw_head_diam =    8.0;
screw_head_thick =  nut_thick;   // for simplicity
pillar_height =     screw_length - (1.25 * nut_thick);

/* bolt passages:
   since we're on a sphere, the height at
   radius x is given by
   
   y = 2 × √(r² - x²)
   
   this drops off very quickly as x → r
   so we probably won't need this
*/
function height_at_radius(d, r) = 2 * sqrt(pow(d / 2, 2) - pow(r, 2));
pillar_diam = nut_diam + 2 * tol + wall_thick;
pillar_at_radius = (ball_diam - 2 * wall_thick - pillar_diam) / 2;
height_at_pillar = height_at_radius(ball_diam, pillar_at_radius);
catch_offset = pillar_at_radius;
echo(pillar_diam=pillar_diam, pillar_at_radius=pillar_at_radius, height_at_pillar=height_at_pillar, catch_offset=catch_offset);

//engraving variables
chars = "MAKERS MAKING CHANGE";
chars2 = "MAKERSMAKINGCHANGE.COM";
radius = (ball_diam/2)-3;
myPi = 3.14159;
chars_per_circle = 40;
step_angle = 360 / chars_per_circle;
circumference = 2 * PI * radius;
char_size = circumference / chars_per_circle;
char_thickness = 1;

module inprofile() {
    // rather than using a sphere, rotate_extrude a 2D path
    offset(r=-3 * wall_thick/2, $fn=16)difference() {
        circle(d=ball_diam, center=true, $fn=32);
        translate([-(ball_diam-(pen_diam + tol))/2, 0])square(ball_diam, center=true);
    }
}

module profile() {
    // 2D path for profile; looks like a letter D, kinda
    union() {
        difference() {
            offset(r=3 * wall_thick / 2, $fn=16)inprofile();
            offset(r=wall_thick / 2, $fn=16)inprofile();
        }
        translate([ball_diam / 2 - wall_thick, 0])square(wall_thick, center=true);
    }
}

module pillars() {
    // solid pillars we shoot the screw/nut holes through
    for(i=[0:2]) {
        rotate([0, 0, i * 120])translate([pillar_at_radius, 0, 0])cylinder(d=pillar_diam, h=2*height_at_pillar, center=true);
    }
}
            
module stiffeners() {
    // pen pipe stiffeners: two, 120 deg apart
    for(i=[0:1]) {
        rotate([0,0,30 + i * 120])rotate([-90, 0, 0])translate([0, 0, (pen_diam + wall_thick)/2])cylinder(d=screw_nom_diam, h=pillar_at_radius);
    }
}

module catch_reinforce() {
    // this is ugly: make a block to take pen-holding screw/nut
    //  but angled so you can print without support
    rotate([90, 0, 0])linear_extrude(height=pillar_diam, center=true)polygon([
    [ pen_diam / 2, catch_offset ],
    [ pen_diam / 2, catch_offset - pillar_diam / 2],
    [ pillar_at_radius, 0 ],
    [ pen_diam / 2, -(catch_offset - pillar_diam / 2)],
    [ pen_diam / 2, -catch_offset ],
    [ pen_diam / 2, -ball_diam/2 ],
    [ ball_diam/2, -ball_diam/2 ],
    [ ball_diam/2, ball_diam/2 ],
    [ pen_diam / 2, ball_diam/2 ],
    ]);
}

module inside_bits() {
    // all of the interior detail, clipped to the outer shell size
    intersection() {
        union() {
            stiffeners();
            pillars();
            catch_reinforce();
        }
        rotate_extrude()offset(r=wall_thick, $fn=16)inprofile();
    }
}

module screw_holes() {
    // three holes around edge: these are negative spaces
    // nut holes have six sides ('cylinder ... $fn=6') as
    // we emulate hex nuts that way: low-poly cylinders!
    for(i=[0:2]) {
        translate([pillar_at_radius * cos(i * 120), pillar_at_radius * sin(i * 120), 0]) {
            cylinder(d=screw_nom_diam + tol, h=ball_diam, center=true, $fn=32);
            translate([0, 0, pillar_height/2])rotate([0, 0, 30])cylinder(d=nut_diam + tol, h=ball_diam, $fn=6);
            translate([0, 0, -1*(ball_diam + pillar_height/2)])cylinder(d=screw_head_diam + tol, h=ball_diam, $fn=32);
        }
    }
}

module nut_catches() {
    // negative space for pen grip screw holes and nut catches
    // top screw hole
    translate([0, 0, catch_offset])rotate([90, 0, 90])union() {
        cylinder(d=screw_nom_diam + tol, h=ball_diam, $fn=32);
        translate([0,0,screw_length+1])cylinder(d=screw_head_diam + tol, h=ball_diam, $fn=32);
        // top nut catch
        translate([0,0,(pen_diam + tol + wall_thick) / 2])hull() {
            rotate([0, 0, 30])cylinder(d=nut_diam + tol, h=nut_thick + tol, $fn=6);
            translate([0, -ball_diam / 2, 0])rotate([0, 0, 30])cylinder(d=nut_diam + tol, h=nut_thick + tol, $fn=6);
        }
    }
    // bottom screw hole
    translate([0, 0, -catch_offset])rotate([90, 0, 90])union() {
        cylinder(d=screw_nom_diam + tol, h=ball_diam, $fn=32);
        translate([0,0,screw_length+1])cylinder(d=screw_head_diam + tol, h=ball_diam, $fn=32);
        // bottom nut catch
        translate([0,0,(pen_diam + tol + wall_thick) / 2])hull() {
            rotate([0, 0, 30])cylinder(d=nut_diam + tol, h=nut_thick + tol, $fn=6);
            translate([0, ball_diam / 2, 0])rotate([0, 0, 30])cylinder(d=nut_diam + tol, h=nut_thick + tol, $fn=6);
        }
    }
}

module shell() {
    // assemble all the things!
    difference() {
        union() {
            // the positive bits
            rotate_extrude()profile();  // outer shell
            inside_bits();              // interior detail
			}
			//engraving text
			for(i = [0 : chars_per_circle - 1]) {
    rotate(i * step_angle) 
        translate([0, radius + char_size / 2, 3]) 
            rotate([90, 0, 180]) linear_extrude(char_thickness) text(
                chars[i], 
                font = "Courier New; Style = Bold", 
                size = char_size, 
                valign = "center", halign = "center"
            );
        }//for (end engraving)
        union() {
            // the negative bits
            screw_holes();              // edge holes
            nut_catches();
        }
    }
}

module slice() {
    // split ball across middle and place halves side by side
    // (lower half flipped) for easy printing
    union() {
        translate([-(ball_diam + pen_diam) / 2, 0, 0]) {
            difference() {
                shell();
                translate([0, 0, -0.6 * ball_diam])cube(1.2 * ball_diam, center=true);
                			//engraving text
			for(i = [0 : chars_per_circle - 1]) {
    rotate(i * step_angle) 
        translate([0, radius + char_size / 2, 3]) 
            rotate([90, 0, 180]) linear_extrude(char_thickness) text(
                chars[i], 
                font = "Courier New; Style = Regular", 
                size = char_size, 
                valign = "center", halign = "center"
            );
        }//for (end engraving)
				}
        }
        translate([(ball_diam + pen_diam) / 2, 0, 0]) {
            difference() {
                rotate([180, 0, 0])shell();
                translate([0, 0, -0.6 * ball_diam])cube(1.2 * ball_diam, center=true);
							//engraving text
			for(i = [0 : chars_per_circle - 1]) {
    rotate(i * step_angle) 
        translate([0, radius + char_size / 2, 3]) 
            rotate([90, 0, 180]) linear_extrude(char_thickness) text(
                chars2[i], 
                font = "Courier New; Style = Bold", 
                size = char_size, 
                valign = "center", halign = "center"
            );
        }//for (end engraving)
            }
        }
    }
}

slice(); // generate the sliced module
