#
#   Door assembly configuration
#

#   Initial configuration to restore after disasters whilst testing

Set restore "Door Assembly" <103, 141, 1200.437> <0, 0, 0, 1>
Set restore "Door handle shaft" <0, 0.33701, 1.27063> <0, 0.70711, 0, 0.70711>
Set restore "Door handle inside" <0.05677, 0.27631, 1.27063> <0.5, -0.5, 0.5, 0.5>
Set restore "Door handle outside" <-0.05755, 0.27708, 1.27063> <0.5, -0.5, 0.5, 0.5>
Set restore "Turntable" <0, 0, 0.14685> <0, 0, 0, 1>
Set restore "Frame L" <0, -0.50998, 1.23633> <0, 0, 0, 1>
Set restore "Hinge bottom" <0, -0.39698, 0.6615> <0, 0, 0, 1>
Set restore "Hinge middle" <0, -0.39698, 1.34876> <0, 0, 0, 1>
Set restore "Hinge top" <0, -0.39698, 1.95068> <0, 0, 0, 1>
Set restore "Panel" <0, 0.00866, 1.23633> <0, 0, 0, 1>
Set restore "Frame R" <0, 0.49901, 1.23633> <0, 0, 0, 1>
Set restore "Door 1" <0, -0.00433, 2.36011> <0, 0, 0, 1>

#   Define parent / child relationships for mechanism

Set parent "Turntable" "Door 1"
    Set parent "Door 1" "Frame L" "Frame R" "Hinge top"
        Set parent "Hinge top" "Hinge middle" "Hinge bottom" "Panel"
            Set parent "Panel" "Door handle shaft"
                Set parent "Door handle shaft" "Door handle inside" "Door handle outside"
