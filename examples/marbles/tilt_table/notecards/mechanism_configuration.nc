#
#   Tilt Table configuration
#

#   Initial configuration to restore after disasters whilst testing

Set restore "Tilt Table" <107.8292, 102.7786, 1200.287> <0, 0, 0, 1>
Set restore "Pivot pillar" <0, 0, 0.28564> <0, 0, 0, 1>
Set restore "Ball joint" <0, 0, 0.71326> <-0, -1, -0, 0>
Set restore "Turntable" <0, 0, 0.02429> <0, 0, 0, 1>
Set restore "Table base" <0, 0, 0.71326> <0, 0, 0, 1>
Set restore "Table side E" <1.5, 0, 0.96326> <0, 0, 0, 1>
Set restore "Table side N" <0, 1.5, 0.96326> <0, 0, 0, 1>
Set restore "Table side W" <-1.5, 0, 0.96326> <0, 0, 0, 1>
Set restore "Table side S" <0, -1.5, 0.96326> <0, 0, 0, 1>
Set restore "Bumper 1" <0.37333, 0.55045, 0.96326> <0, 0, 0, 1>
Set restore "Bumper 2" <-0.68903, -0.98073, 0.96326> <0, 0, 0, 1>
Set restore "Bumper 3" <-0.96076, 0, 0.96326> <0, 0, 0, 1>
Set restore "Bumper 4" <0, 0, 0.96326> <0, 0, 0, 1>
Set restore "Bumper 5" <0.38093, -0.58527, 0.96326> <0, 0, 0, 1>
Set restore "Bumper 6" <-0.53084, 0.79488, 0.96326> <0, 0, 0, 1>

#   Define parent / child relationships for mechanism

Set parent "Turntable"   "Table base" "Pivot pillar"
    Set parent "Table base"   "Ball joint" "Table side N" "Table side E" "Table side W" "Table side S" "Bumper 1" "Bumper 2" "Bumper 3" "Bumper 4" "Bumper 5" "Bumper 6"
