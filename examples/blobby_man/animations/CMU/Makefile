
#       Makefile for producing animations from CMU
#       motion capture files.

TOOLS = ../tools

COMPILER = perl $(TOOLS)/CMUtoSL.pl

BVH_TO_BVM = perl $(TOOLS)/bvh_to_bvm.pl

CHAT_TO_ANIM_SCRIPT = perl ../$(TOOLS)/chat_to_anim_script.pl

#	Archive of original CMU DAZ-format motion capture files
CMU_DAZ = CMU_DAZ

#	CMU animations locally edited with bvhacker and other tools
CMU_EDITED = CMU_EDITED

#	CMU animations locally modified and compiled into SL format as examples
CMU_EXAMPLES = EXAMPLE

#	Blobby Man animation script generation directory
ANIM_SCRIPT = ANIM_SCRIPT

SL_ANIMATIONS = 88_07_cartwheel_double.bvh 86_05_jumping_jacks.bvh \
	124_02_baseball_pitch.bvh 124_07_baseball_swing.bvh \
	141_26_curtsey.bvh 64_01_golf_swing.bvh \
	132_29_bouncy_walk.bvh 91_28_ghetto_walk.bvh

BLOBBY_ANIMATIONS = $(SL_ANIMATIONS:.bvh=.bvm)

BLOBBY_ANIM_SCRIPTS = $(ANIM_SCRIPT)/124_02_baseball_pitch.lsl \
	$(ANIM_SCRIPT)/88_07_cartwheel_double.lsl \
	$(ANIM_SCRIPT)/124_07_baseball_swing.lsl \
	$(ANIM_SCRIPT)/64_01_golf_swing.lsl \
	$(ANIM_SCRIPT)/86_05_jumping_jacks.lsl

#	Frames per second for Second Life animations
FPS = --fps 15

all:		bvh bvm scripts

bvh:		$(SL_ANIMATIONS)

bvm:		$(BLOBBY_ANIMATIONS)

scripts:	$(BLOBBY_ANIM_SCRIPTS)

132_29_bouncy_walk.bvh:		$(CMU_EDITED)/CMU_132_29_bouncy_walk.bvh
	$(COMPILER) $(FPS) $(CMU_EDITED)/CMU_132_29_bouncy_walk.bvh >$@

124_02_baseball_pitch.bvh:	$(CMU_DAZ)/124_02.bvh
	$(COMPILER) --start 1 --end 750 $(FPS) $(CMU_DAZ)/124_02.bvh >$@

124_07_baseball_swing.bvh:	$(CMU_DAZ)/124_07.bvh
	$(COMPILER) --start 2 --end 550 $(FPS) $(CMU_DAZ)/124_07.bvh >$@

141_26_curtsey.bvh:		$(CMU_DAZ)/141_26.bvh
	$(COMPILER) $(FPS) $(CMU_DAZ)/141_26.bvh >$@

91_28_ghetto_walk.bvh:		$(CMU_EDITED)/CMU_91_28_ghetto_walk.bvh
	$(COMPILER) $(FPS) $(CMU_EDITED)/CMU_91_28_ghetto_walk.bvh >$@

64_01_golf_swing.bvh:            $(CMU_DAZ)/64_01.bvh
	$(COMPILER) $(FPS) $(CMU_DAZ)/64_01.bvh >$@

#	These BVH files have been manually edited and are simply
#	copied from the EXAMPLE directory to the work directory.

86_05_jumping_jacks.bvh:		$(CMU_EXAMPLES)/86_05_jumping_jacks.bvh
	cp -p $(CMU_EXAMPLES)/86_05_jumping_jacks.bvh .

88_07_cartwheel_double.bvh:		$(CMU_EXAMPLES)/88_07_cartwheel_double.bvh
	cp -p $(CMU_EXAMPLES)/88_07_cartwheel_double.bvh .

#	Re-format a BVH animation to a BVM file which the
#	Blobby Man can read from a Second Life notecard.
.bvh.bvm:
	$(BVH_TO_BVM) $< >$@

#	Process a Blobby Man animation compiler transcript
#	copied from the Second Life chat window into one or
#	more LSL script files to play the animation.
.chat.lsl:
	( cd $(ANIM_SCRIPT) ; $(CHAT_TO_ANIM_SCRIPT) ../$< )

clean:
	rm -f $(SL_ANIMATIONS) $(BLOBBY_ANIMATIONS) trace.out
	rm -f $(ANIM_SCRIPT)/*.lsl

.SUFFIXES: .bvh .bvm .chat .lsl

FORCE:
