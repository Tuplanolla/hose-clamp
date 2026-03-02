include <BOSL2/std.scad>
include <BOSL2/screws.scad>
include <BOSL2/screw_drive.scad>

/// The following definitions are missing from the support libraries,
/// even though they are very convenient.

/// Linearly (or affinely) map the value `u` from `0` to `1`
/// to the value `v` from `a` to `b`.
// lerp = function (a, b, u)
//   a + (b - a) * u;

/// Linearly (or affinely) map the value `v` from `c` to `d`
/// to the value `u` from `0` to `1`.
lirp = function (c, d, v)
  (v - c) / (d - c);

/// Linearly (or affinely) remap the value `v` from `c` to `d`
/// to the value `u` from `a` to `b`.
lrp = function (c, d, a, b, v)
  lerp(a, b, lirp(c, d, v));

/// Compute the radius (or diameter) `a`
/// of the inscribed circle of an `n`-sided regular polygon
/// from the radius (or diameter) `b` of its circumscribed circle.
/// The default value for `n` is derived
/// from the current `$fn`, `$fa` and `$fs`.
incircle = function (b = 1, n = undef)
  let (n = is_def(n) ? n : segs(b))
  b * cos(180 / n);

/// Compute the radius (or diameter) `b`
/// of the circumscribed circle of an `n`-sided regular polygon
/// from the radius (or diameter) `a` of its inscribed circle.
/// The default value for `n` is derived
/// from the current `$fn`, `$fa` and `$fs`.
circumcircle = function (a = 1, n = undef)
  let (n = is_def(n) ? n : segs(a))
  a / cos(180 / n);

/// The model follows shortly.

$draft = ! true;
$fn = 16;
$eps = 1e-3;
$inf = 1 / $eps;

/// Let us first establish some terminology.
/// The part is called a clamp and it is used
/// for attaching a hose to a boss with a bolt and
/// an optional washer that goes under the head of the bolt.
/// The clamp consists of a hollow guide for the hose and
/// a perforated pair of flaps for the bolt.
/// The guide and flaps are connected by a body,
/// which is split apart to form a small gap.

/// The dimensions of the hose, boss and bolt are out of our control.
hose_diameter = 5;
boss_inner_diameter = 10;
boss_outer_diameter = 12;
boss_counterbore_diameter = 6;
boss_counterbore_depth = 3;
boss_height = 1;
bolt_diameter = 5;
/// The length of the bolt is the length of its shaft,
/// which is fully threaded for no reason.
bolt_length = 12;
bolt_head_diameter = 9.5;
bolt_head_height = 2.5;
/// The size of the drive is the diameter of its inscribed circle,
/// which is also the size of the matching hex key.
/// These measured values are only used
/// to sanity check against standard drive sizes.
bolt_drive_size = 3;
bolt_drive_depth = 2;

/// Basic laws of physics still apply.
assert(hose_diameter > 0);
assert(boss_inner_diameter > 0 &&
       boss_inner_diameter <= boss_outer_diameter);
assert(boss_counterbore_diameter >= bolt_diameter);
assert(boss_counterbore_depth >= 0);
assert(boss_height >= 0);
assert(bolt_diameter > 0);
assert(bolt_length >= boss_counterbore_depth);
assert(bolt_head_diameter >= bolt_diameter);
assert(bolt_head_height >= 0);
assert(bolt_drive_size > 0 &&
       bolt_drive_size <= bolt_head_diameter);
/// The drive depth may exceed the bolt length,
/// in which case the bolt is hollow.
assert(bolt_drive_depth > 0 /* &&
       bolt_drive_depth <= bolt_head_height + bolt_length */);

/// The dimensions of the clamp can be adjusted freely.
guide_length = 17;
guide_thickness = 1;
flaps_thickness = 2;
/// The gap can be omitted,
/// in which case the flaps are fused together.
/// Without the gap, the clamp must be slid on
/// before attaching the hose or putting olives on it.
cut_gap = true;
gap_size = 0.5;
/// If we make the clamp out of a very flexible material,
/// we should add a washer under the head of the bolt,
/// because otherwise the bolt may slip through the hole.
use_washer = true;
washer_inner_diameter = 6;
washer_outer_diameter = 16;
washer_thickness = 1;
/// Edges of the holes can be trimmed to be in line with the body.
/// Untrimmed edges are smoother from the inside,
/// but also less streamlined from the outside.
/// This option only really makes sense
/// when the guide length exceeds the outer diameter of the flaps.
trim_edges = true;
/// These offsets determine the placement of the hose
/// in relation to the boss.
/// Their constraints are not defined until later.
offset_x = - 12;
offset_y = 0;
offset_z = 0;
cut_straight = true;
twist_x = 0;

assert(guide_length > 0);
assert(guide_thickness > 0);
assert(flaps_thickness > 0);
assert(gap_size > 0 &&
       gap_size <= hose_diameter);
assert(washer_inner_diameter > 0 &&
       washer_inner_diameter < washer_outer_diameter);
assert(washer_thickness > 0);
assert(abs(twist_x) <= 90);

/// These options only affect the rendering
/// of the hose, boss, bolt and washer.
render_attachments = true;
hose_extra_length = 20;
boss_depth = 10;

assert(boss_depth > 0);

/// These values for chamfers produce the least sharp corners,
/// but they can be changed to other values within reason.
guide_chamfer_size = guide_thickness / 3;
flap_chamfer_size = flaps_thickness / 4;

/// Reason is such.
assert(guide_chamfer_size >= 0 &&
       guide_chamfer_size <= guide_thickness / 2 &&
       guide_chamfer_size <= guide_length / 2);
assert(flap_chamfer_size >= 0 &&
       flap_chamfer_size <= flaps_thickness / 2);

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

/// This is the diameter of the recess
/// for the bolt and the optional washer.
head_diameter = max(use_washer ? washer_outer_diameter : 0,
                    bolt_head_diameter) + 2 * flap_chamfer_size;
/// This is the diameter of the recess for the boss.
foot_diameter = boss_outer_diameter;
recess_diameter = max(head_diameter, foot_diameter);
/// Referring to the uncorrected gap size
/// from this point on would be a mistake.
cut_size = cut_gap ? gap_size : 0;
cut_angle = cut_straight ? 0 : twist_x;

/// Tightening the bolt reduces the circumference of the guide.
/// We have to correct the diameter of the guide
/// to prevent it from compressing the hose too much.
/// The clamp actually behaves like a folded elastic beam,
/// but we simplify its treatment by assuming
/// that it behaves like a pair of hinged rigid arms.
/// If the bolt crimps the gap around the recesses by this factor,
/// the lengths of the arms can be computed
/// from the surrounding geometry.
crimping = 1;
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
/// but results in maximal compression of the hose
/// as the factor approaches negative infinity.
/// A crimping factor larger than one is also allowed,
/// but diverges at some point due to
/// the guide no longer being able to compress the hose.
assert(crimping < (1 + (guide_thickness / 2 + hose_diameter / 2
                                            + abs(offset_x)) /
                       (recess_diameter / 2)) /
                  2);
/// Inspect these values upon installation to estimate the crimping.
short_arm = guide_thickness / 2 + hose_diameter;
long_arm = guide_thickness / 2 + hose_diameter / 2 + abs(offset_x)
           - (2 * crimping - 1) * recess_diameter / 2;
echo(short_arm = short_arm, long_arm = long_arm);
/// Referring to the uncorrected hose diameter
/// from this point on would be a mistake.
guide_inner_diameter = hose_diameter + (short_arm / long_arm) * cut_size / PI;
guide_outer_diameter = guide_inner_diameter + 2 * guide_thickness;

flaps_depth = flaps_thickness + cut_size;
/// This is the maximum depth of the recesses.
recess_depth = guide_outer_diameter / 2 - flaps_depth / 2 + abs(offset_y);
/// This is the maximum height of the clamp.
body_length = max(guide_length, guide_outer_diameter,
                  recess_diameter, flaps_depth);
/// Hollowing the guide and cutting the clamp benefit
/// from knowing the maximum dimensions of the clamp in any direction.
hollowing_depth = body_length + 2 * abs(offset_z)
                               + sin(abs(cut_angle)) * body_length;

/// The holes should not be offset or twisted so much
/// that the clamp breaks due to self-intersections.
/// Violating these assertions does not necessarily break the clamp,
/// which is why they are disabled by default.
min_offset_x = let (y = guide_inner_diameter / 2 - cut_size / 2
                                                 - guide_thickness / 2)
               (offset_y < y ? head_diameter - 2 * flap_chamfer_size :
                offset_y > - y ? foot_diameter :
                recess_diameter) / 2 + guide_outer_diameter / 2
                                     - guide_thickness / 2;
echo(min_offset_x = min_offset_x, offset_x = offset_x);
* assert(abs(offset_x) >= min_offset_x);

max_offset_y = cut_gap && cut_straight ?
               guide_inner_diameter / 2 - cut_size / 2 :
               $inf;
echo(max_offset_y = max_offset_y, offset_y = offset_y);
* assert(abs(offset_y) <= max_offset_y);

max_offset_z = guide_length / 2 - sin(45) * recess_diameter + abs(offset_x);
echo(max_offset_z = max_offset_z, offset_z = offset_z);
* assert(abs(offset_z) <= max_offset_z);

/// These deformations can be used to nonlinearize the interpolation
/// that stretches the body from the guide to the flaps.
/// The body will be tangent to the holes
/// if the composed deformations have vanishing first derivatives
/// at the endpoints of the domain,
/// which is the unit interval.
deform_domain = function (x) x;
deform_range = function (x) sin(90 * x) ^ 2;

/// If we do not know whether a cylinder is built
/// from the prism of an inscribed or circumscribed regular polygon,
/// we need to use this ratio to be able
/// to cover one cylinder of unknown construction
/// with another cylinder of likewise unknown construction.
scription = circumcircle() / incircle();

/// We use this shape to render the boss and create the recess for it.
module boss(anchor = CENTER, spin = 0, orient = UP)
  let (boss_width = (boss_outer_diameter - boss_inner_diameter) / 2)
  if (boss_width > 0 && boss_height > 0)
    /// The ratio of height to width controls the eccentricity
    /// of the rounding along the perimeter of the boss.
    let (ratio = boss_height / boss_width)
    scale([1, 1, ratio])
    cyl(h = max(boss_depth, recess_depth) / ratio,
        d = boss_outer_diameter,
        rounding2 = boss_width,
        anchor = anchor, spin = spin, orient = orient)
    children();
  else
    cyl(h = max(boss_depth, recess_depth),
        d = boss_outer_diameter,
        anchor = anchor, spin = spin, orient = orient)
    children();

/// We need an M5 bolt with a round head and a hex drive,
/// but this is not supported out of the box.
/// Thus, we split an M5 bolt into its shaft and head,
/// add a round head to the split shaft and
/// replicate the hex drive from the split head into the round head.
module bolt()
  let (info = screw_info("M5", head = "flat", drive = "hex"))
  attachable(h = bolt_length + bolt_head_height,
             d = bolt_diameter,
             offset = [0, 0, bolt_head_height / 2 - bolt_length / 2],
             parts = [define_part("head",
                                  attach_geom(h = bolt_head_height,
                                              d = bolt_head_diameter),
                                  T = move([0, 0, bolt_head_height / 2])),
                      define_part("shaft",
                                  attach_geom(h = bolt_length,
                                              d = bolt_diameter),
                                  T = move([0, 0, - bolt_length / 2]))]) {
    diff()
    screw(struct_set(info,
                     ["head", bolt_head_height > 0 ? "round" : "none",
                      "head_size", bolt_head_diameter,
                      /// The head height must be positive,
                      /// even if there is no head.
                      "head_height", max($eps, bolt_head_height),
                      "drive", "none",
                      "length", max($eps, bolt_length)]),
          anchor = "head_bot")
    attach("head_top", TOP, inside = true, shiftout = $eps)
    hex_drive_mask(struct_val(info, "drive_size"),
                   struct_val(info, "drive_depth"));

    children();
  }

/// Make sure the bolt has a standard drive size.
let (info = screw_info("M5", head = "flat", drive = "hex")) {
  echo(expected_bolt_drive_size = bolt_drive_size,
       actual_bolt_drive_size = struct_val(info, "drive_size"));
  echo(expected_bolt_drive_depth = bolt_drive_depth,
       actual_bolt_drive_depth = struct_val(info, "drive_depth"));
}

/// The washer does not follow any standards.
/// It is whatever could be found in the drawer.
module washer(anchor = CENTER, spin = 0, orient = UP)
  tube(h = washer_thickness,
       od = washer_outer_diameter,
       id = washer_inner_diameter,
       chamfer = washer_thickness / 3,
       anchor = anchor, spin = spin, orient = orient)
  children();

/// The bolt should be tightened until it sits on the threads properly.
/// Without a washer, 45 degrees is good, and
/// with a standard washer, 315 degrees is good,
/// so the following formula usually applies.
bolt_turn = 45 + (use_washer ? 270 * washer_thickness : 0);

if (render_attachments) {
  /// Draw the hose.
  let (h = guide_length + 2 * hose_extra_length)
  if (h > 0)
    % color(plastic, 0.5)
      move([offset_x, offset_y, offset_z])
      rot([cut_angle, 0, 0])
      cyl(h = h, d = hose_diameter, anchor = CENTER);

  /// Draw the boss with a counterbored and threaded insert.
  % color(composite, 0.5)
    bottom_half()
    rot([90, 0, 0])
    move([0, 0, - flaps_depth / 2])
    diff()
    boss(anchor = TOP)
    attach(TOP, TOP, inside = true, shiftout = $eps)
    cyl(h = boss_counterbore_depth + 3 * $eps, d = boss_counterbore_diameter)
    attach(BOT, "shaft_bot", inside = true, shiftout = - $eps)
    screw_hole(struct_set(screw_info("M5", head = "none", drive = "none"),
                          ["length", boss_depth - boss_counterbore_depth]),
               thread = true);

  /// Draw the bolt with the optional washer.
  % color(metal, 0.5)
    rot([90, bolt_turn, 0])
    move([0, 0, flaps_depth / 2 + $eps])
    if (use_washer)
      washer(anchor = BOT)
      /// We do not mention the child anchor `CENTER`,
      /// because its orientation may be that
      /// of either `"head_bot"` or `"shaft_top"`.
      attach(TOP, overlap = - $eps)
      bolt();
    else
      bolt();
}

color(anything)
  difference() {
    union() {
      /// Construct the body.
      if ($draft)
        /// This is a less fancy way of creating the body from a prism.
        /// Alas, it may crease when twisted or
        /// intersect with untrimmed edges of the guide
        /// when the offsets are just right.
        rot([0, 90, 0])
        skin(profiles = [rect([head_diameter, flaps_depth],
                              chamfer = flap_chamfer_size),
                         move([- offset_z, offset_y],
                              rect([guide_length, guide_outer_diameter],
                                   chamfer = guide_chamfer_size,
                                   spin = cut_angle))],
             slices = 0,
             z = [0, offset_x]);
      else
        rot([0, 90, 0])
        let ($fn = max(2, floor($fn / 2)),
             n = floor($fn * guide_length / (2 * abs(offset_x))))
        skin(profiles = [for (i = [0 : $fn - 1])
                         let (y = deform_range(i / ($fn - 1)))
                         move(lerp([0, 0], [- offset_z, offset_y], y),
                              rect(lerp([head_diameter, flaps_depth],
                                        [guide_length, guide_outer_diameter],
                                        y),
                                   chamfer = lerp(flap_chamfer_size,
                                                  guide_chamfer_size,
                                                  y),
                                   spin = lerp(0, cut_angle, y)))],
             slices = 0,
             /// We add refinements
             /// to make the tessellation less acutely angled.
             refine = n,
             z = [for (i = [0 : $fn - 1])
                  let (x = deform_domain(i / ($fn - 1)))
                  lerp(0, offset_x, x)]);

      /// Construct the guide.
      move([offset_x, offset_y, offset_z])
      difference() {
        rot([cut_angle, 0, 0])
        cyl(h = guide_length,
            d = guide_outer_diameter,
            chamfer = guide_chamfer_size);

        if (trim_edges)
          rot([cut_angle, 0, 0])
          cube([scription * guide_outer_diameter / 2 + $eps,
                scription * guide_outer_diameter + 2 * $eps,
                guide_length + 2 * $eps],
               anchor = [sign(offset_x), 0, 0]);
      }

      /// Construct the flaps.
      rot([90, 0, 0])
        difference() {
          cyl(h = flaps_depth,
              d = head_diameter,
              chamfer = flap_chamfer_size);

          if (trim_edges)
            cube([scription * head_diameter / 2 + $eps,
                  scription * head_diameter + 2 * $eps,
                  flaps_depth + 2 * $eps],
                 anchor = [sign(- offset_x), 0, 0]);
        }
    }

    /// Hollow the guide.
    move([offset_x, offset_y, offset_z])
    rot([cut_angle, 0, 0])
    cyl(h = hollowing_depth,
        d = guide_inner_diameter + 2 * $eps,
        extra = $eps,
        chamfer = - (hollowing_depth / 2 - guide_length / 2
                                          + guide_chamfer_size));

    /// Cut the gap.
    if (cut_gap) {
      if (cut_straight) {
        /// Cut from the center of the guide to its edge.
        move([offset_x - $eps, 0, 0])
        cube([guide_inner_diameter / 2 + 2 * $eps,
              cut_size,
              hollowing_depth + 2 * $eps],
             anchor = [sign(offset_x), 0, 0]);

        /// Cut from the edge of the guide to the center of the flaps.
        move([offset_x + guide_inner_diameter / 2, 0, 0])
        cube([abs(offset_x) - guide_inner_diameter / 2,
              cut_size,
              hollowing_depth + 2 * $eps],
             anchor = [sign(offset_x), 0, 0]);

        /// Remove the sharpest edge inside the guide.
        move([offset_x, offset_y, 0])
        move([0, - offset_y / 2, 0])
        cube([guide_inner_diameter / 2,
              abs(offset_y),
              hollowing_depth + 2 * $eps],
             anchor = [sign(offset_x), 0, 0]);

        /// Chamfer the removed edges.
        move([offset_x, offset_y, 0])
        scale([sign(- offset_x), 1, 1])
        skin(profiles = repeat([[0, guide_inner_diameter / 2],
                                [guide_inner_diameter / 2 + guide_chamfer_size, - offset_y + cut_size / 2],
                                [guide_inner_diameter / 2 + guide_chamfer_size, - offset_y - cut_size / 2],
                                [0, - guide_inner_diameter / 2]],
                               2),
             slices = 0,
             /// Skinning does not accept an extra length parameter,
             /// so we have to account for it by hand.
             z = [- hollowing_depth / 2 - $eps, hollowing_depth / 2 + $eps]);
      } else {
        rot([0, 90, 0])
        let ($fn = max(2, floor($fn / 2)))
        skin(profiles = [for (i = [0 : $fn - 1])
                         let (y = deform_range(i / ($fn - 1)))
                         move(lerp([0, 0], [- offset_z, offset_y], y),
                              rot(lerp(0, cut_angle, y),
                                  p = let (x = lrp(0, abs(offset_x), 0, 1,
                                                   abs(offset_x) - guide_inner_diameter / 2
                                                                 - guide_chamfer_size))
                                      y <= deform_range(x) ?
                                      rect([hollowing_depth + 2 * $eps, cut_size]) :
                                      rect(lerp([hollowing_depth + 2 * $eps, cut_size],
                                                [hollowing_depth + 2 * $eps, guide_inner_diameter],
                                                lrp(deform_range(x), 1, 0, 1, y)))))],
             slices = 0,
             refine = floor($fn * hollowing_depth / (2 * abs(offset_x))),
             z = [for (i = [0 : $fn - 1])
                  let (x = deform_domain(i / ($fn - 1)))
                  lerp($eps, offset_x - $eps, x)]);
      }

      /// Cut from the center of the flaps to their edge.
      move([- $eps, 0, 0])
      cube([scription * head_diameter / 2 + 2 * $eps,
            cut_size,
            hollowing_depth + 2 * $eps],
           anchor = [sign(offset_x), 0, 0]);
    }

    /// Perforate the flaps.
    rot([90, 0, 0]) {
      cyl(h = flaps_depth - 2 * $eps, d = bolt_diameter, extra = $eps) {
        /// Cut the recess for the bolt and the optional washer.
        attach(TOP, BOT) {
          /// This is a less fancy way
          /// of creating the recess from a cylinder.
          /// Alas, it may intersect the guide and create a hole
          /// when the offsets are just right.
          if ($draft)
            cyl(h = hollowing_depth + 2 * $eps,
                d = head_diameter + 2 * $eps,
                chamfer1 = flap_chamfer_size,
                anchor = BOT);
          else
            let (d = head_diameter - 2 * flap_chamfer_size + 2 * $eps,
                 n = floor($fn * hollowing_depth / (PI * d)))
            skin([circle(d = d), ellipse(d = [d, d + 2 * hollowing_depth])],
                 z = [0, hollowing_depth + 2 * $eps],
                 /// We add slices
                 /// to make the tessellation less acutely angled.
                 slices = n);
        }

        /// Cut the recess for the boss.
        attach(BOT, TOP)
        /// This prevents z-fighting at the top of the boss.
        move([0, 0, - $eps])
        /// This prevents z-fighting along the perimeter of the boss.
        scale(1 + 2 * $eps / boss_outer_diameter)
        boss();
      }
    }
  }
