#
#   Gimbals mechanism configuration
#

#   Initial configuration to restore after disasters whilst testing

Set restore "Gimbals" <158.3061, 144.8849, 1100.623> <0, 0, 0, 1>
Set restore "Frame +X" <-0.50232, 0, 0.60727> <0, -0.70711, 0, 0.70711>
Set restore "Frame -X" <-0.50232, 0, -0.59274> <0, -0.70711, 0, 0.70711>
Set restore "Z Ring" <-0.99231, 0, 0.00726> <0, 0, 0.70711, 0.70711>
Set restore "Z Pivot B" <-1.34461, 0, 0.00726> <0, -0.70711, 0, 0.70711>
Set restore "Z Pivot A" <-0.64002, 0, 0.00726> <0, -0.70711, 0, 0.70711>
Set restore "X Ring" <-0.99231, 0, 0.00726> <0, 0, 0, 1>
Set restore "X Pivot B" <-0.99231, 0, 0.53229> <0, 0, 0, 1>
Set restore "X Pivot A" <-0.99231, 0, -0.51776> <0, 0, 0, 1>
Set restore "Y Ring" <-0.99231, 0, 0.00726> <0, 0.70711, 0, 0.70711>
Set restore "Y Pivot B" <-0.99231, -0.43085, 0.00726> <0.70711, 0, 0, 0.70711>
Set restore "Y Pivot A" <-0.99231, 0.43085, 0.00726> <0.70711, 0, 0, 0.70711>

#   Define parent / child relationships for mechanism

Set parent "X Ring"   "X Pivot A" "X Pivot B" "Y Ring"
    Set parent "Y Ring"   "Y Pivot A" "Y Pivot B" "Z Ring"
        Set parent "Z Ring"   "Z Pivot A" "Z Pivot B"
