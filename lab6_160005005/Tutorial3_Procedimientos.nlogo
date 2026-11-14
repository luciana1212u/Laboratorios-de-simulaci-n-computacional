turtles-own [energy] ;; for keeping track of when the turtle is ready
                     ;; to reproduce and when it will die

to setup
  clear-all
  setup-patches
  setup-turtles
  reset-ticks
end

to setup-patches
  ask patches [ set pcolor green ]
end

to setup-turtles
  create-turtles number    ;; uses the value of the number slider to create turtles
  ask turtles [ setxy random-xcor random-ycor ]
end

to go
  if ticks >= 500 [ stop ]  ;; stop after 500 ticks
  move-turtles
  eat-grass
  check-death
  reproduce
  regrow-grass
  tick                    ;; increase the tick counter by 1 each time through
end

to move-turtles
  ask turtles [
    right random 360
    forward 1
    set energy energy - 1  ;; when the turtle moves it looses one unit of energy
  ]
end

to eat-grass
  ask turtles [
    if pcolor = green [
      set pcolor black
           ;; the value of energy-from-grass slider is added to energy
      set energy energy + energy-from-grass
    ]
  ifelse show-energy?
    [ set label energy ] ;; the label is set to be the value of the energy
    [ set label "" ]     ;; the label is set to an empty text value
  ]
end

to reproduce
  ask turtles [
    if energy > birth-energy [
      set energy energy - birth-energy  ;; take away birth-energy to give birth
      hatch 1 [ set energy birth-energy ] ;; give this birth-energy to the offspring
    ]
  ]
end

to check-death
  ask turtles [
    if energy <= 0 [ die ] ;; removes the turtle if it has no energy left
  ]
end

to regrow-grass
  ask patches [ ;; 3 out of 100 times, the patch color is set to green
    if random 100 < 3 [ set pcolor green ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
230
10
667
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
15
15
105
48
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
115
15
205
48
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
15
60
105
105
count turtles
count turtles
17
1
11

MONITOR
115
60
205
105
green patches
count patches with [pcolor = green]
17
1
11

SWITCH
15
115
205
148
show-energy?
show-energy?
1
1
-1000

SLIDER
15
160
205
193
number
number
1
1000
100.0
1
1
NIL
HORIZONTAL

SLIDER
15
200
205
233
energy-from-grass
energy-from-grass
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
15
240
205
273
birth-energy
birth-energy
0
100
30.0
1
1
NIL
HORIZONTAL

PLOT
680
10
950
230
Totals
time
totals
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"turtles" 1.0 0 -16777216 true "" "plot count turtles"
"grass" 1.0 0 -10899396 true "" "plot count patches with [pcolor = green]"

@#$#@#$#@
## WHAT IS IT?

Modelo construido siguiendo el Tutorial #3 (Procedures) de NetLogo. Tortugas que se mueven al azar, comen pasto (ganan energía), se reproducen cuando superan birth-energy y mueren si su energía llega a cero. El pasto vuelve a crecer con probabilidad 3 % por tick.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
