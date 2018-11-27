__includes ["parcours.nls" "vector.nls" "movement.nls"]

globals [collisions escaped escaped-1 escaped-2 escaped-3]

turtles-own [
  dead
  hp
  obj
  panic ; 0 = nothing  1 = panic A*  2 = panic flock
  speed
  panic-proba

  agent-type ;1/2/3
  inner-timer
]

patches-own [
 material
 onFire
 onSmoke
]
;;setup simulation

to start-fire
  ask patches [set onFire false
               set onSmoke false]
  ask one-of patches [set onFire true]
  reset-ticks
end

to agent-spawn
  set collisions 0
  set escaped 0
  crt agent-number
    [set color blue - 2 + random 7  ;; random shades look nice
      set size 1 ;; easier to see]
      setxy random-xcor random-ycor
      set dead false
      assign-exit
      set panic 0

      let r random 100
      ifelse r <= presence-type-1
      [
        set agent-type 1
        set hp base-life-1
        set speed base-speed-1
        set panic-proba more-panic-proba-1
        set inner-timer panic-timer-1
      ]
      [
        ifelse r > presence-type-1 and r <= presence-type-1 + presence-type-2
        [
          set agent-type 2
          set hp base-life-2
          set speed base-speed-2
          set panic-proba more-panic-proba-2
          set inner-timer panic-timer-2
        ]
        [; -> if r > presence-type-1 + presence-type-2
          set agent-type 3
          set hp base-life-3
          set speed base-speed-3
          set panic-proba more-panic-proba-3
          set inner-timer panic-timer-3
        ]

      ]

      set fobj factor-obj
      set fobs factor-obstacles
      set falign factor-align
      set fseparate factor-separate
      set fcohere factor-cohere
  ]
  ask turtles [if pcolor = brown [die]
    set path []
    set in-nodes []
    set out-nodes []
    set prefexit min-one-of patches with [exit = true][distance self]
    set current init-current
  ]

  reset-ticks
end


to make-exit
  if mouse-down?
  [ ask patches
    [ if ((abs (pxcor - mouse-xcor)) < 1) and ((abs (pycor - mouse-ycor)) < 1)
      [ set pcolor yellow
        set exit true]]]
  display
end

;;simulation treatment

to spread-fire
 ask neighbors [
    if pcolor = black or pcolor = gray[
    let r random 100
      if r <= fire-proba [set onFire true
                          set onSmoke true]
    ]
  ]
end

to spread-smoke
 ask neighbors [
    if pcolor = black[
    let r random 100
      if r <= smoke-proba [set onSmoke true]]
  ]
end

to update-color
  if onFire = true
  [set pcolor red]
  if onSmoke = true and onFire = false
  [set pcolor gray]
end

to damage
  if pcolor = grey
  [ set hp hp - smoke-damage ]
  if pcolor = red
  [ set hp hp - fire-damage ]

end

to clear-body
  if dead = true and (pcolor = red or obstacle = true)
  [ die ]
end

to assign-exit
  set prefexit one-of patches with [pcolor = yellow]
end

to check-death
  if hp <= 0 [
    set dead true
    set color green
  ]
end

to escape
  if pcolor = yellow
  [ set escaped escaped + 1

    if agent-type = 1 [set escaped-1 escaped-1 + 1]
    if agent-type = 2 [set escaped-2 escaped-2 + 1]
    if agent-type = 3 [set escaped-3 escaped-3 + 1]

    die
  ]
end


to go
  ask patches with [onFire = true] [update-color spread-fire]
  ask patches with [onSmoke = true] [update-color spread-smoke]
  ask turtles with [dead = false] [update-panic color-panic damage count-collisions]
  ask turtles with [panic = 1 and dead = false] [A* see-exit check-coll]
  ask turtles with [panic = 2 and dead = false] [flock see-exit check-coll set inner-timer inner-timer - 1]
  ask turtles [check-death damage clear-body escape]
  tick
end



to find-exit
 set obj patches in-cone fov-radius fov-angle with [pcolor = yellow]
 if any? obj
  [let x one-of obj ;;pour chaque sortie visible
  if x != prefexit ;;si la sortie n'est pas celle que l'agent connaissait
     [let r random 100
    if r < objective-choice-chance ;;l'agent peut changer de sortie favorite selon une certaine proba
    [set prefexit x ;;modifier la sortie préférée
    stop]];;ne pas continuer à parcourir les sorties encore en vues
  ]
end

to see-exit
  let ex patches in-cone fov-radius fov-angle with [pcolor = yellow]
  if any? ex
  [ set heading towards one-of ex ]
end

to update-panic
  let others turtles in-cone fov-radius fov-angle with [panic != 0]
  let deads turtles in-cone fov-radius fov-angle with [color = green]
  if any? others  and panic = 0 [set panic 1]
  let fire patches in-cone fov-radius fov-angle with [pcolor = red or pcolor = grey]
  if any? fire or any? deads
  [
    ifelse panic = 0
    [
      set panic 1
    ]
    [
      if panic = 1
      [
        let r random 100
        if r <= panic-proba
        [
          set panic 2
          if agent-type = 1 [ set speed speed + sprint-1 ]
          if agent-type = 2 [ set speed speed + sprint-2 ]
          if agent-type = 3 [ set speed speed + sprint-3 ]
        ]
      ]
    ]
  ]

   if panic = 2 and inner-timer <= 0
    [
      set panic 1
      if agent-type = 1 [ set speed speed - sprint-1 set inner-timer panic-timer-1 ]
      if agent-type = 2 [ set speed speed - sprint-2 set inner-timer panic-timer-2 ]
      if agent-type = 3 [ set speed speed - sprint-3 set inner-timer panic-timer-3 ]
    ]
end

to color-panic
  if panic = 1 [set color yellow]
  if panic = 2 [set color orange]
end


to panic-all
  ask turtles [set panic 1]
end



;;global simulation functions

to count-collisions
  if pcolor != black [set collisions collisions + 1]
end

to clear
  clear-all
  reset-ticks
end
@#$#@#$#@
GRAPHICS-WINDOW
12
10
577
576
-1
-1
16.9
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
0
0
1
ticks
30.0

TEXTBOX
615
10
775
28
Agent parameters
14
0.0
1

TEXTBOX
795
10
945
28
Movement ponderation
14
0.0
1

BUTTON
169
586
286
619
Start simulation
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
3
625
114
658
Spawn Agents
agent-spawn
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
448
628
549
661
Spawn Walls
spawn-walls
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
291
587
394
620
Start the fire
start-fire
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
10
592
160
610
Simulation configuration
14
0.0
1

SLIDER
971
111
1143
144
agent-number
agent-number
0
100
10.0
1
1
NIL
HORIZONTAL

BUTTON
292
667
410
700
Clear simulation
clear
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
586
35
758
68
min-dist
min-dist
0
20
0.0
0.5
1
NIL
HORIZONTAL

BUTTON
119
625
237
658
Draw Obstacles
make-obstacles
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1481
42
1602
87
Number of collisions
collisions
17
1
11

TEXTBOX
1512
14
1662
32
Display
14
0.0
1

SLIDER
587
74
759
107
max-angle-turn
max-angle-turn
0
360
30.0
1
1
NIL
HORIZONTAL

BUTTON
334
627
440
660
Setup from Model
import-model
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
778
78
950
111
factor-align
factor-align
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
778
34
950
67
factor-separate
factor-separate
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
777
125
949
158
factor-cohere
factor-cohere
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
778
168
950
201
factor-obstacles
factor-obstacles
0
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
972
148
1144
181
fire-proba
fire-proba
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
971
184
1143
217
smoke-proba
smoke-proba
0
100
6.0
1
1
NIL
HORIZONTAL

SLIDER
972
35
1144
68
smoke-damage
smoke-damage
0
50
4.0
1
1
NIL
HORIZONTAL

SLIDER
972
72
1144
105
fire-damage
fire-damage
0
50
20.0
1
1
NIL
HORIZONTAL

BUTTON
243
625
328
658
Draw Exit
make-exit
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1485
159
1544
204
NIL
escaped
17
1
11

SLIDER
584
393
756
426
fov-angle
fov-angle
0
360
120.0
1
1
NIL
HORIZONTAL

SLIDER
584
432
756
465
fov-radius
fov-radius
0
10
6.0
1
1
patches
HORIZONTAL

SLIDER
778
211
950
244
factor-obj
factor-obj
0
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
586
117
770
150
objective-choice-chance
objective-choice-chance
0
100
10.0
1
1
NIL
HORIZONTAL

BUTTON
399
587
554
620
Compute A* Algorithm
search-turtles
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
82
669
199
702
Panic all agents
panic-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
585
159
757
192
next-patch-range
next-patch-range
0
20
3.0
1
1
NIL
HORIZONTAL

TEXTBOX
985
10
1173
34
Environment parameters
14
0.0
1

TEXTBOX
597
374
747
392
Vision
14
0.0
1

TEXTBOX
588
255
944
326
IMPORTANT! \nYou must setup walls, exit and agents before computing A* algorithm !\nStart the fire just before to start simulation !
14
0.0
1

PLOT
602
510
893
660
Population
temps
Agent
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Escaped" 1.0 0 -1184463 true "" "plot escaped"
"Total" 1.0 0 -16777216 true "" "plot count turtles"

MONITOR
1485
110
1542
155
agents
count turtles
17
1
11

TEXTBOX
1205
10
1355
28
Panic
14
0.0
1

TEXTBOX
979
285
1129
303
Type 1 (vieu)
14
0.0
1

TEXTBOX
1166
286
1316
304
Type 2 (adulte)
14
0.0
1

TEXTBOX
1353
287
1503
305
Type 3 (enfant)
14
0.0
1

SLIDER
924
317
1096
350
base-life-1
base-life-1
0
150
60.0
1
1
NIL
HORIZONTAL

SLIDER
924
361
1096
394
base-speed-1
base-speed-1
0
2
0.4
0.1
1
NIL
HORIZONTAL

SLIDER
924
402
1096
435
more-panic-proba-1
more-panic-proba-1
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
1104
316
1276
349
base-life-2
base-life-2
0
150
150.0
1
1
NIL
HORIZONTAL

SLIDER
1287
316
1459
349
base-life-3
base-life-3
0
150
90.0
1
1
NIL
HORIZONTAL

SLIDER
924
440
1096
473
presence-type-1
presence-type-1
0
100 - presence-type-2 - presence-type-3
34.0
1
1
NIL
HORIZONTAL

SLIDER
1105
361
1277
394
base-speed-2
base-speed-2
0
2
1.2
0.1
1
NIL
HORIZONTAL

SLIDER
1287
361
1459
394
base-speed-3
base-speed-3
0
2
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
1104
402
1276
435
more-panic-proba-2
more-panic-proba-2
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
1289
402
1461
435
more-panic-proba-3
more-panic-proba-3
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
1104
440
1276
473
presence-type-2
presence-type-2
0
100 - presence-type-1 - presence-type-3
33.0
1
1
NIL
HORIZONTAL

SLIDER
1288
439
1460
472
presence-type-3
presence-type-3
0
100 - presence-type-1 - presence-type-2
33.0
1
1
NIL
HORIZONTAL

PLOT
925
566
1458
716
Agent Type Population
temps
agent
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Type 1" 1.0 0 -5825686 true "" "plot count turtles with [agent-type = 1]"
"Type 2" 1.0 0 -11221820 true "" "plot count turtles with [agent-type = 2]"
"Type 3" 1.0 0 -2674135 true "" "plot count turtles with [agent-type = 3]"
"Escaped type 1" 1.0 0 -8630108 true "" "plot escaped-1"
"Escaped type 2" 1.0 0 -13345367 true "" "plot escaped-2"
"Escaped type 3" 1.0 0 -955883 true "" "plot escaped-3"

SLIDER
924
481
1096
514
sprint-1
sprint-1
0
1.0
0.2
0.1
1
NIL
HORIZONTAL

SLIDER
1104
481
1276
514
sprint-2
sprint-2
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
1288
481
1460
514
sprint-3
sprint-3
0
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
925
519
1097
552
panic-timer-1
panic-timer-1
0
20
12.0
1
1
tick
HORIZONTAL

SLIDER
1104
520
1276
553
panic-timer-2
panic-timer-2
0
20
6.0
1
1
tick
HORIZONTAL

SLIDER
1289
520
1461
553
panic-timer-3
panic-timer-3
0
20
20.0
1
1
tick
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
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
