include <BOSL2/std.scad>
include <BOSL2/screws.scad>
include <BOSL2/screw_drive.scad>

$fn = $fn > 0 ? $fn : 16;
$eps = 1e-3;
$inf = 1 / $eps;

/// Let us first establish some terminology.
/// The part is called a clamp and it is used
/// for attaching a hose to a boss with a bolt.
/// The clamp consists of a guide hole for the hose and
/// a flap hole for the bolt.
/// The holes are connected together by a body,
/// which is split apart by a gap.
///
/// The dimensions of the hose, boss and bolt are out of our control.
hose_diameter = 5;
boss_inner_diameter = 10;
boss_outer_diameter = 12;
boss_counterbore_diameter = 6;
boss_counterbore_depth = 3;
boss_height = 1;
bolt_diameter = 5;
bolt_length = 12;
bolt_head_diameter = 9.5;
bolt_head_height = 2.5;
/// This size of the drive is the inscribed diameter of the hexagon,
/// which is also the size of the matching Allen key.
bolt_drive_size = 3;
bolt_drive_depth = 2;
/// The other dimensions can be adjusted freely,
/// although there are some constraints that need to be satisfied.
hose_extra_length = 30;
guide_length = 20;
guide_thickness = 1;
flap_thickness = 1;
gap_size = 0.5;
washer_inner_diameter = 6;
washer_outer_diameter = 16;
washer_thickness = 1;
/// The offsets determine the placement of the hose
/// in relation to the boss.
offset_x = 15;
offset_y = - 1.25;
offset_z = 0;

/// This flag controls the shape of the edges of the holes.
/// Untrimmed edges are smoother from the inside,
/// but also less streamlined from the outside.
trim_edges = true;
/// This flag determines whether there should be a washer.
/// If we make the clamp out of a very flexible material,
/// we should add a washer under the head of the bolt,
/// because otherwise the bolt may slip through the flaps.
use_washer = true;
/// This flag toggles the rendering of the hose, boss, bolt and washer.
render_attachments = true;

/// These values for chamfers produce the least sharp corners,
/// but they can be changed to other values within reason.
guide_chamfer_size = guide_thickness / 3;
flap_chamfer_size = flap_thickness / 2;

/// Reason is such.
assert(guide_chamfer_size >= 0 &&
       guide_chamfer_size <= guide_thickness / 2);
assert(flap_chamfer_size >= 0 &&
       flap_chamfer_size <= flap_thickness);

/// This is the diameter of the recess for the bolt and the washer.
head_diameter = max(use_washer ? washer_outer_diameter : 0,
                    bolt_head_diameter) + 2 * flap_chamfer_size;
/// This is the diameter of the recess for the boss.
foot_diameter = boss_outer_diameter;
recess_diameter = max(head_diameter, foot_diameter);

/// The bolt should be tightened until it sits on the threads properly.
/// Without a washer, 45 degrees is good, and
/// with a millimeter washer, 315 degrees is good.
bolt_turn = 45 + (use_washer ? 270 * washer_thickness : 0);

/// Tightening the bolt reduces the circumference of the guide.
/// We have to correct the diameter of the guide
/// to prevent it from compressing the hose too much.
/// The clamp actually behaves like a folded elastic beam,
/// but we simplify its treatment by assuming
/// that it behaves like a pair of hinged rigid arms.
/// If the bolt crimps the gap around the recesses by this factor,
/// the lengths of the arms can be computed
/// from the surrounding geometry.
crimping = 0.5;
/// The crimping factor has a few distinct regimes.
///
/// * A crimping factor of zero means that
///   there is one hinge at the back of the guide.
///   The hinge makes the flaps meet at their farthest point.
/// * A crimping factor of one half means that there
///   is a hinge at the back of the guide and
///   another hinge in the middle of the flaps.
///   The hinges make the flaps meet in the middle.
/// * A crimping factor of one means that
///   there is a hinge at the back of the guide and
///   another hinge on the outer edge of the flaps.
///   The hinges make the flaps meet at their nearest point.
///
/// A crimping factor smaller than zero is allowed,
/// but it approaches maximal compression of the hose
/// as the factor approaches negative infinity.
/// A crimping factor larger than one is also allowed,
/// but diverges at some point due to
/// the guide no longer touching the hose.
assert(crimping < (1 + (guide_thickness / 2 + hose_diameter / 2 + offset_x) /
                       (recess_diameter / 2)) /
                  2);
/// The crimping can be estimated
/// by inspecting these values upon installation.
short_arm = guide_thickness / 2 + hose_diameter;
long_arm = guide_thickness / 2 + hose_diameter / 2 + offset_x -
           (2 * crimping - 1) * recess_diameter / 2;
echo(short_arm = short_arm, long_arm = long_arm);
guide_diameter = hose_diameter + (short_arm / long_arm) * gap_size / PI;

/// The holes cannot be offset so much that clamp intersects itself.
assert(offset_x >= guide_diameter / 2 + guide_thickness + recess_diameter / 2);
assert(abs(offset_y) <= guide_diameter / 2 - gap_size / 2);
// assert(abs(offset_z) <= guide_length / 2 - recess_diameter / 2);

/// These deformations can be used to nonlinearize the interpolation
/// that stretches the body from the guide to the flaps.
/// The body will be tangent to the holes
/// if the composed deformations have vanishing first derivatives
/// at the endpoints of the domain,
/// which is the unit interval.
deform_domain = function (x) x;
deform_range = function (x) sin(90 * x) ^ 2;

/// We follow a color scheme that makes it easy
/// to distinguish different materials.
/// Carbon fiber composite with steel or brass inserts
/// is drawn with violet--purple hues.
composite = "MediumOrchid";
/// Aluminum or steel with protective plating or coating
/// is drawn with blue--gray hues.
metal = "LightSteelBlue";
/// Any material with synthetic rubber or plastic sheathing
/// is drawn with yellow--green--teal hues.
plastic = "OliveDrab";
/// Any other material is drawn with the default gold color.
anything = "Gold";

/// This is the longer of the two sides.
max_length = max(guide_length, head_diameter);

/// We use this shape in rendering the boss and
/// creating the recess for it.
module boss(anchor = CENTER, spin = 0, orient = UP) {
  let (boss_width = (boss_outer_diameter - boss_inner_diameter) / 2,
       /// This ratio controls the eccentricity of the rounding.
       ratio = boss_height / boss_width)
    attachable(anchor, spin, orient,
               d = boss_outer_diameter,
               l = (bolt_length - boss_counterbore_depth) / ratio) {
      scale([1, 1, ratio])
      cyl(h = (bolt_length - boss_counterbore_depth) / ratio,
          d = boss_outer_diameter,
          rounding2 = boss_width);

      children();
    }
}

/// We need an M5 bolt with a round head and a hex drive,
/// but BOSL does not support bolts like this.
/// Thus, we split an M5 bolt into its shaft and head,
/// add a round head to the split shaft and
/// replicate the hex drive from the split head into the round head.
module bolt(anchor = CENTER, spin = 0, orient = UP) {
  let (offset = bolt_length / 2 - bolt_head_height / 2,
       info = screw_info("M5", head = "flat", drive = "hex"))
    attachable(anchor, spin, orient,
               geom = attach_geom(d = bolt_diameter,
                                  h = bolt_length + bolt_head_height,
                                  cp = [0, 0, offset],
                                  offset = [0, 0, - offset])) {
      diff()
        screw(struct_set(info,
                         ["head", "round",
                          "head_size", bolt_head_diameter,
                          "head_height", bolt_head_height,
                          "drive", "none",
                          "length", bolt_length]))
        attach("head_top", TOP, inside = true)
        hex_drive_mask(struct_val(info, "drive_size"),
                       struct_val(info, "drive_depth"));

      children();
    }
}

/// Make sure the bolt has a standard drive size.
let (info = screw_info("M5", head = "flat", drive = "hex")) {
  echo(expected_bolt_drive_size = bolt_drive_size,
       actual_bolt_drive_size = struct_val(info, "drive_size"));
  echo(expected_bolt_drive_depth = bolt_drive_depth,
       actual_bolt_drive_depth = struct_val(info, "drive_depth"));
}

module washer(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient,
             d = washer_outer_diameter,
             l = washer_thickness) {
    tube(h = washer_thickness,
         od = washer_outer_diameter,
         id = washer_inner_diameter);

    children();
  }
}

if (render_attachments) {
  % color(plastic, 0.5)
    move([- offset_x, offset_y, offset_z])
    // module hose(anchor = CENTER, spin = 0, orient = UP)
    cyl(h = guide_length + 2 * hose_extra_length,
        d = hose_diameter,
        anchor = CENTER);

  % color(composite, 0.5)
    bottom_half()
    move([0, $eps, 0])
    rot([90, 0, 0])
    move([0, 0, - (2 * flap_thickness + gap_size) / 2])
    // module boss_with_insert(anchor = CENTER, spin = 0, orient = UP)
    diff()
    boss(anchor = TOP)
    attach(TOP, TOP, inside = true)
    cyl(h = boss_counterbore_depth,
        d = boss_counterbore_diameter,
        extra = 2 * $eps)
    attach(BOT, "shaft_bot", inside = true)
    screw_hole(struct_set(screw_info("M5", head = "none", drive = "none"),
                          ["length", (bolt_length - boss_counterbore_depth) - boss_counterbore_depth]),
               thread = true);

  % color(metal, 0.5)
    rot([90, bolt_turn, 0])
    move([0, 0, flap_thickness + gap_size / 2])
    if (use_washer)
      move([0, 0, washer_thickness]) {
        washer(anchor = TOP);
        bolt();
      }
    else
      bolt();
}

color(anything)
  difference() {
    union() {
      /// module body()
      /// This is a less fancy way of creating the skin.
      /// However, it may also create jagged edges.
      * rot([0, 90, 0])
        skin(profiles = [move([- offset_z, offset_y],
                              rect([guide_length, guide_diameter + 2 * guide_thickness],
                                   chamfer = guide_chamfer_size)),
                         rect([head_diameter, 2 * flap_thickness + gap_size],
                              chamfer = flap_chamfer_size)],
             slices = 0,
             z = [- offset_x, 0]);

      rot([0, 90, 0])
        let ($fn = max(2, $fn / 2))
        skin(profiles = [for (i = [0 : $fn - 1])
                         let (y = deform_range(i / ($fn - 1)))
                         move(lerp([- offset_z, offset_y], [0, 0], y),
                              rect(lerp([guide_length, guide_diameter + 2 * guide_thickness],
                                        [head_diameter, 2 * flap_thickness + gap_size],
                                        y),
                                   chamfer = lerp(guide_chamfer_size, flap_chamfer_size, y)))],
             slices = 0,
             z = [for (i = [0 : $fn - 1])
                  let (x = deform_domain(i / ($fn - 1)))
                  lerp(- offset_x, 0, x)]);

      /// module guide()
      move([- offset_x, offset_y, offset_z])
        difference() {
          cyl(h = guide_length,
              d = guide_diameter + 2 * guide_thickness,
              chamfer = guide_chamfer_size);

          if (trim_edges)
            /// Suppose the side length is `a`.
            /// The radius of an inscribed circle is `a / sqrt(3)` and
            /// the radius of a circumscribed circle is `sqrt(3) * a / 6`.
            /// Their ratio is `1 / 2`.
            /// If we do not know whether the cylinder is inscribed or circumscribed,
            /// we should be able to always cover it if we double the radius.
            cube([hose_diameter + guide_thickness + $eps,
                  2 * hose_diameter + 2 * guide_thickness + 2 * $eps,
                  guide_length + 2 * $eps],
                 anchor = LEFT);
        }

      /// module flaps()
      rot([90, 0, 0])
        difference() {
          cyl(h = 2 * flap_thickness + gap_size,
              d = head_diameter,
              chamfer = flap_chamfer_size);

          if (trim_edges)
            cube([head_diameter + $eps,
                  2 * head_diameter + 2 * $eps,
                  2 * flap_thickness + gap_size + 2 * $eps],
                 anchor = RIGHT);
        }
    }

    /// module coguide()
    move([- offset_x, offset_y, offset_z]) {
      /// This hollows the guide.
      * cyl(h = guide_length,
          d = guide_diameter,
          extra = 2 * $eps,
          chamfer = - guide_chamfer_size);
      cyl(h = max_length + 2 * abs(offset_z),
          d = guide_diameter,
          extra = 2 * $eps,
          chamfer = - guide_chamfer_size - (max_length - guide_length) / 2 - abs(offset_z));

        /// This cuts the sharp corner rubbing the hose.
        cube([guide_diameter / 2, abs(offset_y),
              max_length + 2 * $eps],
             anchor = LEFT + BACK * sign(offset_y));

        /// This chamfers the cut.
        skin(profiles = [for (i = [- 1, 0, 0, 1])
                         let (chamfer = abs(i) * guide_chamfer_size)
                         [[0, - guide_diameter / 2 - chamfer],
                          [guide_diameter / 2 + guide_chamfer_size + chamfer, - offset_y - gap_size / 2],
                          [offset_x - head_diameter / 2, - offset_y - gap_size / 2],
                          [offset_x - head_diameter / 2, - offset_y + gap_size / 2],
                          [guide_diameter / 2 + guide_chamfer_size + chamfer, - offset_y + gap_size / 2],
                          [0, guide_diameter / 2 + chamfer]]],
             slices = 0,
             z = [- max_length / 2 - $eps,
                  - max_length / 2 + guide_chamfer_size,
                  max_length / 2 - guide_chamfer_size,
                  max_length / 2 + $eps]);
    }

    /// module coflaps()
    rot([90, 0, 0]) {
      /// This hollows the flaps.
      cyl(h = 2 * flap_thickness + gap_size,
          d = bolt_diameter,
          extra = 2 * $eps);
    }

    rot([90, 0, 0])
      let (y = ((guide_diameter + 2 * guide_thickness) - (2 * flap_thickness + gap_size)) / 2)
      union() {
        /// This is a less fancy way of creating the recess.
        /// However, it may also violate an assertion about self-intersection.
        * move([0, 0, (2 * flap_thickness + gap_size) / 2])
          cyl(h = y - offset_y,
              d = head_diameter,
              extra = $eps, anchor = BOT,
              chamfer1 = flap_chamfer_size);

        move([0, 0, (2 * flap_thickness + gap_size) / 2])
          /// We rotate the circle to align the slices better.
          skin([rot(180 / $fn, p = circle(d = head_diameter - 2 * flap_chamfer_size)),
                ellipse(d = [head_diameter - 2 * flap_chamfer_size,
                             lerp(head_diameter - 2 * flap_chamfer_size,
                                  head_diameter,
                                  (y - offset_y) / flap_chamfer_size)])],
               z = [0, y - offset_y],
               /// We add slices to make the faces less acutely angled.
               slices = floor($fn * (y - offset_y) / (PI * head_diameter)));

        move([0, 0, - (2 * flap_thickness + gap_size) / 2])
        boss(anchor = TOP);
      }

    /// This cuts the gap through the part.
    move([- offset_x, 0, offset_z / 2])
      cube([offset_x + head_diameter / 2 + $eps,
            gap_size,
            max_length + abs(offset_z) + 2 * $eps],
           anchor = LEFT);
  }
