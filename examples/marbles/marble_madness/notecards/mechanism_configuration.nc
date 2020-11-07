#
#   Marble Madness configuration
#

#   Initial configuration to restore after disasters whilst testing

Set restore "Marble Madness" <136.2395, 112.7546, 1200.448> <0, 0, 0, 1>
Set restore "Pivot pillar" <0, 0, 0.17822> <0, 0, 0, 1>
Set restore "Ball joint" <0, 0, 0.3407> <-0, -1, -0, 0>
Set restore "S end" <0, -1.49055, 0.48291> <0, 0, 0.70711, 0.70711>
Set restore "SSE side" <0.24976, -0.87459, 0.4834> <0.5, 0.5, 0.5, 0.5>
Set restore "SSW side" <-0.24512, -0.86134, 0.4834> <0.5, 0.5, 0.5, 0.5>
Set restore "N end" <0, 1.49961, 0.48254> <0, 0, 0.70711, 0.70711>
Set restore "NNE side" <0.25, 0.87296, 0.4834> <0.5, 0.5, 0.5, 0.5>
Set restore "NNW side" <-0.24094, 0.87296, 0.4834> <0.5, 0.5, 0.5, 0.5>
Set restore "E end" <1.49962, 0, 0.48792> <0, 0, 0, 1>
Set restore "W end" <-1.49259, 0, 0.48572> <0, 0, 0, 1>
Set restore "WNW side" <-0.87006, 0.2471, 0.48669> <0.70711, 0, 0, 0.70711>
Set restore "WSW side" <-0.87006, -0.24535, 0.48669> <0.70711, 0, 0, 0.70711>
Set restore "ESE side" <0.87648, -0.24829, 0.48669> <0.70711, 0, 0, 0.70711>
Set restore "ENE side" <0.87648, 0.25626, 0.48669> <0.70711, 0, 0, 0.70711>
Set restore "EW Arm base" <0, 0, 0.3407> <0, 0, 0, 1>
Set restore "NS Arm base" <0, 0, 0.3407> <0, 0, 0.70711, 0.70711>
Set restore "Turntable" <0, 0, 0.02429> <0, 0, 0, 1>

#   Define parent / child relationships for mechanism

Set parent "Turntable"   "NS Arm base" "Pivot pillar"
    Set parent "NS Arm base"   "Ball joint" "N end" "NNE side" "NNW side" "S end" "SSE side" "SSW side"  "EW Arm base"  "E end" "ENE side" "ESE side" "W end" "WNW side" "WSW side"
