
#       Makefile for producing animations from the
#       Second Life standard internal animations.

TOOLS = ../tools

BVH_TO_BVM = perl $(TOOLS)/bvh_to_bvm.pl

CHAT_TO_ANIM_SCRIPT = perl ../$(TOOLS)/chat_to_anim_script.pl

#	Archive of original Second Life internal animations
SL = SL

#	Blobby Man animation script generation directory
ANIM_SCRIPT = ANIM_SCRIPT

BLOBBY_ANIMATIONS = SL_Avatar_Tpose.bvm avatar_backflip.bvm \
	avatar_bow.bvm avatar_dance1.bvm avatar_female_walk.bvm \
	avatar_hello.bvm avatar_jumpforjoy.bvm avatar_peace.bvm \
	avatar_salute.bvm avatar_sit_female.bvm avatar_sit_ground.bvm \
	avatar_walk.bvm

BLOBBY_ANIM_SCRIPTS = $(BLOBBY_ANIMATIONS:.bvm=.lsl)

#	Frames per second for Second Life animations
FPS = --fps 15

all:		bvm scripts

bvm:		$(BLOBBY_ANIMATIONS)

scripts:	$(BLOBBY_ANIM_SCRIPTS)

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
	rm -f $(BLOBBY_ANIMATIONS) trace.out
	rm -f $(ANIM_SCRIPT)/*.lsl

.SUFFIXES: .bvh .bvm .chat .lsl

VPATH = .:SL:ANIM_SCRIPT

FORCE:
