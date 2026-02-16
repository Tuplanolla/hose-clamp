/// This produces a Shimano brake hose clamp for the Tandell PLUS29 Boost fork.

#include <BOSL2/std.scad>

/// This is a convenient shorthand for making nice spheres.
module sph(r, d, circum = false, dual = false,
           anchor = CENTER, spin = 0, orient = UP) {
  let (r = get_radius(r = r, d = d, dflt = 1))
    attachable(anchor, spin, orient, r = r) {
      if ($fn % 5 == 0)
        spheroid(r = r, style = "icosa", circum = circum, dual = dual,
                 anchor = anchor, spin = spin, orient = orient);
      else if ($fn % 4 == 0)
        spheroid(r = r, style = "octa", circum = circum, dual = dual,
                 anchor = anchor, spin = spin, orient = orient);
      else
        spheroid(r = r, style = "stagger", circum = circum, dual = dual,
                 anchor = anchor, spin = spin, orient = orient);

      children();
    }
}

$draft = ! true;
$fn = 24;
$eps = 0.001;
$inf = 1000;

/// The number of facets for rounding.
/// The mnemonic is smoothing corners.
sfn = 4;
/// The number of facets for skinning.
/// The mnemonic is linear interpolation.
lfn = 16;

hose_diameter = 5;
hose_length = 15;
bolt_diameter = 5;
bolt_length = 3;
/// The diameter of the head of the bolt is 9.5 mm and
/// the diameter of the boss varies smoothly from 6 mm to 11 mm.
head_diameter = 9.5;
hole_separation = 10;
hole_offset = 1;
hole_shift = 0;
thickness = 1.5;
gap_size = 0.5;
sharp_cut = ! true;
trim_edges = ! true;
rounding_size = 1;

/// The system actually behaves like an elastic beam,
/// but we simplify its treatment by assuming
/// that it behaves like a pair of hinged rigid arms.
/// If the bolt crimps the hole for the boss completely,
/// the lengths of the rigid arms are the following.
long_arm = (hole_separation / 2 + hose_diameter / 2) +
           (hole_separation / 2 - head_diameter / 2);
short_arm = hose_diameter / 2;
echo(short_arm = short_arm, long_arm = long_arm);
/// This reduces the circumference of the hole for the hose,
/// which we correct as follows.
diameter = hose_diameter + (short_arm / long_arm) * gap_size / PI;
rounding = $draft ? 0 : rounding_size;

/// OpenSCAD will crash if you change the variables
/// to almost violate this assertion,
/// so consider not doing that.
assert(rounding < thickness);
// echo("CGAL error in CGAL_Nef_polyhedron3(): CGAL ERROR: assertion violation! Expr: e_below != SHalfedge_handle() File: /usr/include/CGAL/Nef_3/SNC_FM_decorator.h Line: 418");

assert(abs(hole_shift) <= hose_length / 2 - head_diameter / 2);
assert(abs(hole_offset) <= hose_diameter / 2 - gap_size / 2);

/// These functions can be used to nonlinearize the interpolation.
deform_domain = function (x) x;
deform_range = function (x) sin(90 * x) ^ 2;

/// This is a visual reference for the Minkowski sum.
move([hole_separation / 2, hole_separation / 2, hole_separation / 2])
  %sph(d = rounding_size, $fn = sfn);

render()
  difference() {
    /// There are more efficient ways to do rounding,
    /// but this is simple and works.
    minkowski() {
      if (rounding > 0)
        sph(d = rounding, $fn = sfn);

      difference() {
        union() {
          move([- hole_separation, - hole_offset, - hole_shift])
            difference() {
              cyl(d = diameter + 2 * thickness - rounding,
                  h = hose_length - rounding);

              if (trim_edges)
                cube([$inf, $inf, $inf], anchor = LEFT);
            }

          /*
          rot([0, 90, 0])
            skin(profiles = [move([hole_shift, - hole_offset],
                                  rect([hose_length - rounding, diameter + 2 * thickness - rounding])),
                             rect([head_diameter - rounding, bolt_length + gap_size - rounding])],
                 z = [- hole_separation, 0],
                 slices = 0);
          */

          rot([0, 90, 0])
            let ($fn = lfn)
            skin(profiles = [for (i = [0 : $fn - 1])
                             let (y = deform_range(i / ($fn - 1)))
                             move((1 - y) * [hole_shift, - hole_offset],
                                  rect(lerp([hose_length - rounding, diameter + 2 * thickness - rounding],
                                            [head_diameter - rounding, bolt_length + gap_size - rounding],
                                            y)))],
                 z = [for (i = [0 : $fn - 1])
                      let (x = deform_domain(i / ($fn - 1)))
                      lerp(- hole_separation, 0, x)],
                 slices = 0);

          rot([90, 0, 0]) {
            difference() {
              cyl(d = head_diameter - rounding,
                  h = bolt_length + gap_size - rounding);

              if (trim_edges)
                cube([$inf, $inf, $inf], anchor = RIGHT);
            }
          }
        }

        move([- hole_separation, - hole_offset, - hole_shift]) {
          cyl(d = diameter + rounding,
              h = hose_length + rounding, extra = 2 * $eps);

          /// This removes the sharp corner rubbing the hose.
          move([0, hole_offset / 2, 0])
            cube([hose_diameter / 2 + rounding / 2, abs(hole_offset),
                  hose_length + rounding + 2 * $eps], anchor = LEFT);
        }

        rot([90, 0, 0])
          let (y = ((diameter + 2 * thickness - rounding) - (bolt_length + gap_size - rounding)) / 2)
          union() {
            cyl(d = bolt_diameter + rounding,
                h = bolt_length + gap_size - rounding, extra = y);

            mirror_copy([0, 0, 1])
              move([0, 0, (bolt_length + gap_size - rounding) / 2])
              cyl(d = head_diameter - rounding,
                  h = y, anchor = BOTTOM);
          }

        if (! sharp_cut)
          move([- hole_separation, 0, 0])
            cube([$inf, gap_size + rounding, $inf], anchor = LEFT);
      }
    }

    if (sharp_cut)
      move([- hole_separation, 0, 0])
        cube([$inf, gap_size, $inf], anchor = LEFT);
  }
