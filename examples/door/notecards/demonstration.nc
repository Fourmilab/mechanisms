
#   Door mechanism demonstration

@panic gently

@script pause 3

@echo Open the door

Door open

@script pause 5

@echo Close the door

Door close

@script pause 5

@echo Rotate the platform on which the door stands by 45 degrees.

RL Turntable <0, 0, 1> 45

@script pause 3

@echo Open and shut the rotated door.

Door open
@script pause 5
Door close
@script pause 5

@echo The rotated door works just as before.

@script pause 3

@panic gently
@script pause 2

@echo Let's try it on a spinning door.

Spin Turntable <0, 0, 1> 0.5 1

@script pause 2

Door open
@script pause 5
Door close
@script pause 5

@echo Now let's do a Twilight Zone door.

Spin Turntable <0, 0.1, 1> 0.25 1
Spin Door <0.25, 0.1, 0.3> 0.33 1

@script pause 3

@echo Will it still open and close correctly?

Door open
@script pause 5
Door close
@script pause 5

@echo Yes, it does!

@script pause 4
@panic gently

@echo Here is the definition of the mechanism in the notecard.
@echo Components are specified by their link names.  There
@echo are five levels of hierarchy in the mechanism.
@echo

@echo Set parent "Turntable" "Door 1"
@echo     Set parent "Door 1" "Frame L" "Frame R" "Hinge top"
@echo         Set parent "Hinge top" "Hinge middle" "Hinge bottom" "Panel"
@echo             Set parent "Panel" "Door handle shaft"
@echo                 Set parent "Door handle shaft" "Door handle inside" "Door handle outside"

@echo

@script pause 3

@echo For more information, see the documentation notecards.

