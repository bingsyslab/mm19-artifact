.PHONY: psnr-ssim-rand ts-rand psnr-ssim-ts-rand cdfs pdfs clean-cdfs clean-pdfs clean clean-remaps clean-views clean-lt-views clean-logs clean-all prepare-dataset prepare-ffmpeg

.SECONDEXPANSION:

SHELL := /bin/bash
SELF := ./makefile
PWD := $(shell pwd)





#
# Setup the paths to ffmpeg, ffprobe, and etc.
#

# ffmpeg
export FFMPEG_DIR := $(PWD)/ffmpeg
export FFMPEG := $(FFMPEG_DIR)/ffmpeg
export FFPROBE := $(FFMPEG_DIR)/ffprobe

# remap.pl path
export REMAP_DIR := $(PWD)
export REMAP := $(REMAP_DIR)/remap.pl

# layout files (*.lt) path
export LAYOUT_DIR := $(PWD)/layouts
export CUBE_LT := $(LAYOUT_DIR)/cube.lt
export MV_LT := $(LAYOUT_DIR)/good_normal.lt
export EQRECT_LT := $(LAYOUT_DIR)/equirectangular.lt

# shader files (*.glsl) path
export SHADER_DIR := $(PWD)/shaders
export EQRECT_GLSL := $(SHADER_DIR)/equirectangular.glsl
export EQRECT_EAC_GLSL := $(SHADER_DIR)/equirectangular-eac.glsl
export SIMPLE_VERTEX_GLSL := $(SHADER_DIR)/simpleVertex.glsl
export EQDIS_GLSL := $(SHADER_DIR)/eqdis.glsl
export EQDIS_ECOEF_GLSL := $(SHADER_DIR)/eqdis-ecoef.glsl
export EQDIS_ECOEF25_GLSL := $(SHADER_DIR)/test-glsls/eqdis-ecoef25.glsl
export UNEQDEG_GLSL := $(SHADER_DIR)/uneqdeg.glsl
export UNEQDEG_ECOEF_GLSL := $(SHADER_DIR)/uneqdeg-ecoef.glsl
export UNEQDEG_ECOEF25_GLSL := $(SHADER_DIR)/test-glsls/uneqdeg-ecoef25.glsl
export VERTEX_GLSL := $(SHADER_DIR)/vertex.glsl
export EQDEG_GLSL := $(SHADER_DIR)/eqdeg.glsl





#
# Help info
#
help:
	@printf "prepare-ffmpeg:    automatically download and build ffmpeg with 360-project filter\n"
	@printf "prepare-dataset:   automatically download and uncompress the dataset\n"
	@printf "psnr-ssim-ts-rand: measure PSNR, SSIM and rendering time with randomly chosen TIMES_NR video segments and UIDS_NR orientations\n"
	@printf "cdfs:              collect data into *.cdf files\n"
	@printf "pdfs:              plot CDF figures\n"
	@printf "clean-cdfs:        remove *.cdf\n"
	@printf "clean-pdfs:        remove *.pdf\n"
	@printf 'clean-remaps:      remove $$VNAME/$$SCHEME/remaps/*.mp4\n'
	@printf 'clean-hd-views:    remove $$VNAME/views/*.mp4\n'
	@printf 'clean-lt-views:    remove $$VNAME/$$SCHEME/views/*.mp4\n'
	@printf 'clean-logs:        remove $$VNAME/$$SCHEME/psnr/*.log, $$VNAME/$$SCHEME/ssim/*.log, $$VNAME/$SCHEME/ts/*.log\n'
	@printf 'help:              this information.\n'





#
# Setup the experiment parameters
#

# videos to evaluate
# The video directory should looks like
# Diving/
#   |- 1280/
#      |- ${time}_sec.mp4
#      |- ...
#      |- uid-${uid}_raw.txt
#      |- ...
#
# Diving Paris Rollercoaster Timelapse Venise
# Conan_Gore_Fly Cooking_Battle Front Help Rhinos Conan_Weird_Al Football Tahiti_Surf
# Anitta FemaleBasketball Fighting Korean Reloaded RioVR TFBoy VoiceToy
VNAMES ?= Diving Paris Rollercoaster Timelapse Venise Conan_Gore_Fly Cooking_Battle Front Help Rhinos Conan_Weird_Al Football Tahiti_Surf Anitta FemaleBasketball Fighting Korean Reloaded RioVR TFBoy VoiceToy

MOVING_VNAMES ?= Diving Rollercoaster Tahiti_Surf Front
STATIC_VNAMES ?= $(filter-out $(MOVING_VNAMES),$(VNAMES))
V_TYPES := moving static

# layouts to evaluate
# choose from "cube", "eac", and "mv"
export LAYOUTS ?= cube eac mv
export CUBE_RES ?= 1920x1280
export EAC_RES ?= 1920x1280
export MV_RES ?= 2240x832

# FoV angles
export FOV ?= 100x100

# The view video resolution
export VIEW_RES ?= 800x800

# schemes to evaluate (crf$(nr), e.g., crf23, and cbr${nr}, e.g., cbr500k)
export SCHEMES ?= crf23

# users to evaluate (max is the number of uid-${uid}_raw.txt files)
export UIDS_NR ?= 20

# segments to evaluate (max is the number of ${time}_sec.mp4 files
export TIMES_NR ?= 10


prepare-dataset: dataset.tgz
	tar xfz $<

dataset.tgz:
	wget https://dl.dropboxusercontent.com/s/snlomfjoh7ybsk3/dataset.tgz

prepare-ffmpeg: ffmpeg/
	cd ffmpeg && \
	git reset --hard 37e4c226c06c4ac6b8e3a0ccb2c0933397d6f96f && \
	$(RM) libavfilter/gl_utils.c libavfilter/gl_utils.h libavfilter/vf_project.c && \
	git apply ../360_project.patch && \
	./configure --enable-gpl --enable-libx264 --extra-libs='-lglfw -lGLEW -lGL -lGLU' && \
	make -j8

ffmpeg/:
	git clone https://github.com/FFmpeg/FFmpeg ffmpeg


#
# Experiments
#

# Generate remap videos, views, and psnr/ssim from randomly generated video segments and user orientations
# The results are stored at ${VNAME}/${SCHEME}/psnr/, ${VNAME}/${SCHEME}/ssim/, ${VNAME}/${SCHEME}/ts/

psnr-ssim-rand:
	chmod +x $(REMAP)
	for vname in $(VNAMES); do \
	  cp makefile.sub $$vname/makefile ; \
	  make -C $$vname remap-videos view-videos psnr-logs ssim-logs; \
	done


# Measure the processing time of ffmpeg360
# "sudo time ${CMD}" is used, so this needs superuser privilege
ts-rand:
	chmod +x $(REMAP)
	for vname in $(VNAMES); do \
	  cp makefile.sub $$vname/makefile; \
	  make -C $$vname remap-videos ts-logs; \
	done

psnr-ssim-ts-rand:
	chmod +x $(REMAP)
	for vname in $(VNAMES); do \
	  cp makefile.sub $$vname/makefile; \
	  make -C $$vname remap-videos view-videos psnr-logs ssim-logs ts-logs; \
	done

remap-videos:
	for vname in $(VNAMES); do \
	  cp makefile.sub $$vname/makefile; \
	  make -C $$vname remap-videos; \
	done

view-videos: remap-videos
	for vname in $(VNAMES); do \
	  cp makefile.sub $$vname/makefile; \
	  make -C $$vname view-videos; \
	done

psnr-logs: view-videos
	for vname in $(VNAMES); do  \
	  cp makefile.sub $$vname/makefile; \
	  make -C $$vname psnr-logs; \
	done

ssim-logs: view-videos
	for vname in $(VNAMES); do  \
	  cp makefile.sub $$vname/makefile; \
	  make -C $$vname ssim-logs; \
	done

ts-logs: remap-videos
	for vname in $(VNAMES); do  \
	  cp makefile.sub $$vname/makefile; \
	  make -C $$vname ts-logs; \
	done



#
# Collect data for CDFs
#

CDF_PL := ./cdf.pl

MOVING_PSNR_CDFS := $(foreach scheme,$(SCHEMES),$(foreach lt,$(LAYOUTS),$(lt).psnr_avg.$(scheme)-psnr.moving.cdf))
STATIC_PSNR_CDFS := $(foreach scheme,$(SCHEMES),$(foreach lt,$(LAYOUTS),$(lt).psnr_avg.$(scheme)-psnr.static.cdf))
MOVING_SSIM_CDFS := $(foreach scheme,$(SCHEMES),$(foreach lt,$(LAYOUTS),$(lt).All.$(scheme)-ssim.moving.cdf))
STATIC_SSIM_CDFS := $(foreach scheme,$(SCHEMES),$(foreach lt,$(LAYOUTS),$(lt).All.$(scheme)-ssim.static.cdf))
MOVING_SIZE_CDFS := $(foreach scheme,$(SCHEMES),$(foreach lt,$(LAYOUTS),$(lt).size.$(scheme)-remaps.moving.cdf))
STATIC_SIZE_CDFS := $(foreach scheme,$(SCHEMES),$(foreach lt,$(LAYOUTS),$(lt).size.$(scheme)-remaps.static.cdf))
TS_CDFS          := $(foreach scheme,$(SCHEMES),$(foreach lt,$(LAYOUTS),$(lt).ts.$(scheme)-ts.cdf))

MOVING_CDFS := $(MOVING_PSNR_CDFS) $(MOVING_SSIM_CDFS) $(MOVING_SIZE_CDFS)
STATIC_CDFS := $(STATIC_PSNR_CDFS) $(STATIC_SSIM_CDFS) $(STATIC_SIZE_CDFS)
MOVING_STATIC_CDFS := $(MOVING_CDFS) $(STATIC_CDFS) $(TS_CDFS)

%.moving.cdf: $(CDF_PL)
	$(CDF_PL) $(foreach i,1 2,$(word $(i),$(subst ., ,$*))) \
	$(foreach vname,$(MOVING_VNAMES),$(addsuffix /$(subst -,/,$(lastword $(subst ., ,$*))),$(vname))) > $@

%.static.cdf: $(CDF_PL)
	$(CDF_PL) $(foreach i,1 2,$(word $(i),$(subst ., ,$*))) \
	$(foreach vname,$(STATIC_VNAMES),$(addsuffix /$(subst -,/,$(lastword $(subst ., ,$*))),$(vname))) > $@

PSNR_CDFS := $(foreach scheme,$(SCHEMES),$(foreach lt,$(LAYOUTS),$(lt).psnr_avg.$(scheme)-psnr.cdf))
SSIM_CDFS := $(foreach scheme,$(SCHEMES),$(foreach lt,$(LAYOUTS),$(lt).All.$(scheme)-ssim.cdf))
SIZE_CDFS := $(foreach scheme,$(SCHEMES),$(foreach lt,$(LAYOUTS),$(lt).size.$(scheme)-remaps.cdf))

CDFS := $(PSNR_CDFS) $(SSIM_CDFS) $(SIZE_CDFS) $(TS_CDFS)
%.cdf: $(CDF_PL)
	$(CDF_PL) $(foreach i,1 2,$(word $(i),$(subst ., ,$*))) \
	$(foreach vname,$(VNAMES),$(addsuffix /$(subst -,/,$(lastword $(subst ., ,$*))),$(vname))) > $@

moving-cdfs: $(MOVING_CDFS)
static-cdfs: $(STATIC_CDFS)
moving-static-cdfs: $(MOVING_STATIC_CDFS)
cdfs: $(CDFS)

cdfs.tgz: $(CDFS)
	tar cfz $@ $^

clean-cdfs:
	$(RM) *.cdf



#
# Plot CDFs for segment sizes, PSNR, and SSIM
#

MOVING_PSNR_CDF_PDF := $(foreach scheme,$(SCHEMES),psnr_avg.$(scheme)-psnr.moving.pdf)
STATIC_PSNR_CDF_PDF := $(foreach scheme,$(SCHEMES),psnr_avg.$(scheme)-psnr.static.pdf)
MOVING_SSIM_CDF_PDF := $(foreach scheme,$(SCHEMES),All.$(scheme)-ssim.moving.pdf)
STATIC_SSIM_CDF_PDF := $(foreach scheme,$(SCHEMES),All.$(scheme)-ssim.static.pdf)
MOVING_SIZE_CDF_PDF := $(foreach scheme,$(SCHEMES),size.$(scheme)-remaps.moving.pdf)
STATIC_SIZE_CDF_PDF := $(foreach scheme,$(SCHEMES),size.$(scheme)-remaps.static.pdf)
TS_CDF_PDF   := $(foreach scheme,$(SCHEMES),ts.$(scheme)-ts.pdf)

MOVING_CDF_PDF := $(MOVING_PSNR_CDF_PDF) $(MOVING_SSIM_CDF_PDF) $(MOVING_SIZE_CDF_PDF)
STATIC_CDF_PDF := $(STATIC_PSNR_CDF_PDF) $(STATIC_SSIM_CDF_PDF) $(STATIC_SIZE_CDF_PDF)
MOVING_STATIC_CDF_PDF := $(MOVING_CDF_PDF) $(STATIC_CDF_PDF) $(TS_CDF_PDF)

CDF_GP := cdf.gp
TITLES := CUBE EAC MVL

psnr_moving_xrange := [10:50]
psnr_static_xrange := [20:50]
define PSNR_PLOT_RULE
psnr_avg.$(scheme)-psnr.$(vt).pdf: $$(foreach lt,$(LAYOUTS),$$(lt).psnr_avg.$(scheme)-psnr.$(vt).cdf) $(CDF_GP) $(SELF)
	gnuplot -e 'set output "$$@"' \
	-e 'set xrange $$(psnr_$(vt)_xrange)' \
	-e 'set xlabel "PSNR (dB)"' \
	-e 'titles = "$(TITLES)"' \
	-e 'datafiles = "$$(filter %.cdf,$$^)"' \
	$(CDF_GP)
endef

ssim_moving_xrange := [0.6:1]
ssim_static_xrange := [0.92:1]
define SSIM_PLOT_RULE
All.$(scheme)-ssim.$(vt).pdf: $$(foreach lt,$(LAYOUTS),$$(lt).All.$(scheme)-ssim.$(vt).cdf) $(CDF_GP) $(SELF)
	gnuplot -e 'set output "$$@"' \
	-e 'set xrange $$(ssim_$(vt)_xrange)' \
	-e 'set xlabel "SSIM"' \
	-e 'titles = "$(TITLES)"' \
	-e 'datafiles = "$$(filter %.cdf,$$^)"' \
	$(CDF_GP)
endef

size_moving_xrange :=[0.6:1.19]
size_static_xrange :=[0.6:1.19]
define SIZE_PLOT_RULE
size.$(scheme)-remaps.$(vt).pdf: $$(filter-out cube.%,$$(foreach lt,$(LAYOUTS),$$(lt).size.$(scheme)-remaps.$(vt).cdf)) $(CDF_GP) $(SELF)
	gnuplot -e 'set output "$$@"' \
	-e 'set xrange $$(size_$(vt)_xrange)' \
	-e 'set xlabel "Normalized Segment Sizes"' \
	-e 'titles = "$$(filter-out CUBE,$(TITLES))"' \
	-e 'datafiles = "$$(filter %.cdf,$$^)"' \
	$(CDF_GP)
endef

time_xrange := [8:30]
define TIME_PLOT_RULE
ts.$(scheme)-ts.pdf: $$(foreach lt,$(LAYOUTS),$$(lt).ts.$(scheme)-ts.cdf) $(CDF_GP) $(SELF)
	gnuplot -e 'set output "$$@"' \
	-e 'set xrange $$(time_xrange)' \
	-e 'set xlabel "Time (ms)"' \
	-e 'titles = "$(TITLES)"' \
	-e 'datafiles = "$$(filter %.cdf,$$^)"' \
	$(CDF_GP)
endef

$(foreach scheme,$(SCHEMES), \
  $(foreach vt,$(V_TYPES), \
    $(eval $(PSNR_PLOT_RULE)) \
    $(eval $(SSIM_PLOT_RULE)) \
    $(eval $(SIZE_PLOT_RULE)) \
  ) \
)

$(foreach scheme,$(SCHEMES), \
  $(eval $(TIME_PLOT_RULE)) \
)


PSNR_CDF_PDF := $(foreach scheme,$(SCHEMES),psnr_avg.$(scheme)-psnr.pdf)
SSIM_CDF_PDF := $(foreach scheme,$(SCHEMES),All.$(scheme)-ssim.pdf)
SIZE_CDF_PDF := $(foreach scheme,$(SCHEMES),size.$(scheme)-remaps.pdf)
CDF_PDF := $(PSNR_CDF_PDF) $(SSIM_CDF_PDF) $(SIZE_CDF_PDF) $(TS_CDF_PDF)

psnr_xrange := [10:50]
define BOTH_PSNR_PLOT_RULE
psnr_avg.$(scheme)-psnr.pdf: $$(foreach lt,$(LAYOUTS),$$(lt).psnr_avg.$(scheme)-psnr.cdf) $(CDF_GP) $(SELF)
	gnuplot -e 'set output "$$@"' \
	-e 'set xrange $$(psnr_xrange)' \
	-e 'set xlabel "PSNR (dB)"' \
	-e 'titles = "$(TITLES)"' \
	-e 'datafiles = "$$(filter %.cdf,$$^)"' \
	$(CDF_GP)
endef

ssim_xrange := [0.6:1]
define BOTH_SSIM_PLOT_RULE
All.$(scheme)-ssim.pdf: $$(foreach lt,$(LAYOUTS),$$(lt).All.$(scheme)-ssim.cdf) $(CDF_GP) $(SELF)
	gnuplot -e 'set output "$$@"' \
	-e 'set xrange $$(ssim_xrange)' \
	-e 'set xlabel "SSIM"' \
	-e 'titles = "$(TITLES)"' \
	-e 'datafiles = "$$(filter %.cdf,$$^)"' \
	$(CDF_GP)
endef

time_xrange := [0.6:1.19]
define BOTH_SIZE_PLOT_RULE
size.$(scheme)-remaps.pdf: $$(filter-out cube.%,$$(foreach lt,$(LAYOUTS),$$(lt).size.$(scheme)-remaps.cdf)) $(CDF_GP) $(SELF)
	gnuplot -e 'set output "$$@"' \
	-e 'set xrange $$(time_xrange)' \
	-e 'set xlabel "Normalized Segment Sizes"' \
	-e 'titles = "$$(filter-out CUBE,$(TITLES))"' \
	-e 'datafiles = "$$(filter %.cdf,$$^)"' \
	$(CDF_GP)
endef

$(foreach scheme,$(SCHEMES), \
  $(eval $(BOTH_PSNR_PLOT_RULE)) \
  $(eval $(BOTH_SSIM_PLOT_RULE)) \
  $(eval $(BOTH_SIZE_PLOT_RULE)) \
)

moving-pdfs: $(MOVING_CDF_PDF)
static-pdfs: $(MOVING_CDF_PDF)
moving-static-pdfs: $(MOVING_STATIC_CDF_PDF)
pdfs: $(CDF_PDF)

clean-pdfs:
	$(RM) *.pdf



#
# Clean up
#
clean: clean-cdfs clean-pdfs

clean-remaps:
	for vname in $(VNAMES); do \
	  if [ -d $$vname ]; then \
	    cp makefile.sub $$vname/makefile; \
	    make -C $$vname clean-remaps; \
	  fi; \
	done
clean-views:
	for vname in $(VNAMES); do \
	  if [ -d $$vname ]; then \
	    cp makefile.sub $$vname/makefile; \
	    make -C $$vname clean-views; \
	  fi; \
	done
clean-lt-views:
	for vname in $(VNAMES); do \
	  if [ -d $$vname ]; then \
	    cp makefile.sub $$vname/makefile; \
	    make -C $$vname clean-lt-views; \
	  fi; \
	done
clean-logs:
	for vname in $(VNAMES); do \
	  if [ -d $$vname ]; then \
	    cp makefile.sub $$vname/makefile; \
	    make -C $$vname clean-logs; \
	  fi; \
	done
clean-all:
	for vname in $(VNAMES); do \
	  if [ -d $$vname ]; then \
	    cp makefile.sub $$vname/makefile; \
	    make -C $$vname clean-all; \
	  fi; \
	done

