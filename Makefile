OPENSCAD=openscad
PNGFN=256
STLFN=64

all : flexible-clamp.stl flexible-clamp.png clamps.png
.PHONY : all

flexible-clamp.stl : clamp.scad
	$(OPENSCAD) \
	-D '$$fn = $(STLFN)' \
	-o $@ $<

clamps.png : rigid-clamp.png short-clamp.png convex-clamp.png tightened-clamp.png \
             uncut-clamp.png long-clamp.png concave-clamp.png loosened-clamp.png
	montage $^ -geometry +0+0 $@

flexible-clamp.png : clamp.scad
	$(OPENSCAD) \
	-D '$$fn = $(PNGFN)' \
	-D 'hose_extra_length = 30' \
	--camera 0,0,0,60,0,45,100 \
	--imgsize 800,800 \
	--projection ortho \
	--view axes,scales \
	-o $@ $<

rigid-clamp.png : clamp.scad
	$(OPENSCAD) \
	-D '$$fn = $(PNGFN)' \
	-D 'use_washer = false' \
	-D 'hose_extra_length = 30' \
	--camera 0,0,0,60,0,45,100 \
	--imgsize 800,800 \
	--projection ortho \
	-o $@ $<

uncut-clamp.png : clamp.scad
	$(OPENSCAD) \
	-D '$$fn = $(PNGFN)' \
	-D 'flaps_thickness = 1' \
	-D 'cut_gap = false' \
	-D 'flap_chamfer_size = flaps_thickness / 3' \
	-D 'hose_extra_length = 30' \
	--camera 0,0,0,60,0,45,100 \
	--imgsize 800,800 \
	--projection ortho \
	-o $@ $<

short-clamp.png : clamp.scad
	$(OPENSCAD) \
	-D '$$fn = $(PNGFN)' \
	-D 'use_washer = false' \
	-D 'guide_length = 2' \
	-D 'guide_thickness = 2' \
	-D 'offset_y = 0' \
	-D 'hose_extra_length = 30' \
	--camera 0,0,0,60,0,45,100 \
	--imgsize 800,800 \
	--projection ortho \
	-o $@ $<

long-clamp.png : clamp.scad
	$(OPENSCAD) \
	-D '$$fn = $(PNGFN)' \
	-D 'guide_length = 35' \
	-D 'guide_thickness = 2' \
	-D 'use_washer = false' \
	-D 'trim_edges = false' \
	-D 'offset_y = 0' \
	-D 'offset_z = - 5' \
	-D 'hose_extra_length = 30' \
	--camera 0,0,0,60,0,45,100 \
	--imgsize 800,800 \
	--projection ortho \
	-o $@ $<

convex-clamp.png : clamp.scad
	$(OPENSCAD) \
	-D '$$fn = $(PNGFN)' \
	-D 'offset_x = - 9.1' \
	-D 'offset_y = 2.27' \
	-D 'hose_extra_length = 30' \
	--camera 0,0,0,60,0,11.4,100 \
	--imgsize 800,800 \
	--projection ortho \
	-o $@ $<

concave-clamp.png : clamp.scad
	$(OPENSCAD) \
	-D '$$fn = $(PNGFN)' \
	-D 'offset_x = - 11.1' \
	-D 'offset_y = - 2.27' \
	-D 'hose_extra_length = 30' \
	--camera 0,0,0,60,0,53.2,100 \
	--imgsize 800,800 \
	--projection ortho \
	-o $@ $<

tightened-clamp.png : clamp.scad
	$(OPENSCAD) \
	-D '$$fn = $(PNGFN)' \
	-D 'use_washer = false' \
	-D 'offset_x = - 14' \
	-D 'offset_y = 2' \
	-D 'offset_z = - 2' \
	-D 'cut_straight = false' \
	-D 'twist_x = 45' \
	-D 'hose_extra_length = 5' \
	--camera 0,0,0,60,0,45,100 \
	--imgsize 800,800 \
	--projection ortho \
	-o $@ $<

loosened-clamp.png : clamp.scad
	$(OPENSCAD) \
	-D '$$fn = $(PNGFN)' \
	-D 'use_washer = true' \
	-D 'offset_x = - 14' \
	-D 'offset_y = 2' \
	-D 'offset_z = - 2' \
	-D 'cut_straight = false' \
	-D 'twist_x = - 45' \
	-D 'hose_extra_length = 5' \
	--camera 0,0,0,60,0,45,100 \
	--imgsize 800,800 \
	--projection ortho \
	-o $@ $<
