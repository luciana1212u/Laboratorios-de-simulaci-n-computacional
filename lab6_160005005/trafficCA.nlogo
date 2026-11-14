globals
[
 
  grid-x-inc  ;; the amount of patches in between two streets in the x direction
  grid-y-inc  ;; the amount of patches in between two streets in the y direction
  
  phase
  
  ;; patch agentsets
  streets
  traffic-lights
  upstreams
  intersections
  hstreets ;; horizontal streets
  vstreets ;; 
  Sstreets ;; Southbound streets
  Nstreets ;; Northbound streets
  Estreets ;; Eastbound streets
  Wstreets ;; Westbound streets
  
  intersections-to-monitor
  intersection-to-monitor
  intersection-to-monitor2
  intersection-to-monitor3
  intersection-to-monitor4
  corr-intersections-stats?
  street-to-monitor
  
  ;; string and list variables that hold data passed accumulated in the model run
  #cars
  #cars-old
  flow
  flow-data 
  car-intervals-street
  
  ;; variables for information measures
  swI;;Information for intersection switches
  ciI;;Information for cars at intersections
  csI;;Information for cars at street
]

patches-own
[
  on? 
  was-on?
  rule
  l ;;"left" cell
  r ;; "right" cell
  green-horizontal?;tells whether green light is for horizontal streets...
  all-stop? ;; tells whether all directions should have a red light (with SOLA only).
  was-all-stop? ;; tells whether intersection should turn back to one green
  switch-asap ; tells whether TL should switch...
  intersection?
  traffic-light?
  upstream?
  street?
  horizontal?
  vertical?
  southbound? 
  eastbound?  
  northbound?
  westbound?
  monitor?
  switch-intervals
  car-intervals-intersection
  mob? ;; whether it is a moebius border cell
  var
  
  ;;SOLA intersection variables
  kappa ;; number of cars * number of time steps waiting
  greensteps ;; steps since last change of lights to green 
  carsteps   ;; steps since last car passed by
  switchsteps;; steps since last light switch
  
  r1
  r2
  r3
  r4
  r5
  ooo
  ooi
  oio
  oii
  ioo
  ioi
  iio
  iii

  
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  print ""
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  set   corr-intersections-stats? false
  ;;set   corr-intersections-stats? true
  setup-streets
  init-lists
    ask hstreets  ;; randomly place cells across the top of the world
    [
      set on? (random-float 100) < (density * ((100 - %vertical) * 2) / 100)
      color-patch
    ]
    ask vstreets  ;; randomly place cells across the top of the world
    [
      set on? ((random-float 100) < (density * (%vertical * 2) / 100))
      color-patch
    ]
  ;;make real density close to probabilistic one...
  let density_OK? false
  while [not density_OK?][
    ;ifelse floor(100 * (count streets with [on?]) / (count streets)) > density [
    ifelse (100 * (count streets with [on?] - 0.5) > (density * (count streets))) [
      ask one-of streets with [on?][
        set on? false
      ]
    ][
      ;ifelse floor(100 * (count streets with [on?]) / (count streets)) < density [
      ifelse (100 * (count streets with [on?] + 0.5) < (density * (count streets)))[
        ask one-of streets with [not on?][
          set on? true
        ]
      ][
        set density_OK? true
      ]
    ]  
  ]
  
  
  ask streets 
  [
    color-patch
  ]
  
  set #cars count streets with [on?]
end

to setup-streets
  set grid-y-inc world-height / grid-size-y
  ifelse grid-size-x > 0[;intersections
    set grid-x-inc world-width / grid-size-x  
  ][;no intersections
    set grid-x-inc world-width * 3
  ]
       
  set streets patches with [ (floor ((pxcor + max-pxcor - floor(grid-x-inc / 2)) mod grid-x-inc) = 0) or
                           (floor ((pycor + max-pycor  - floor(grid-y-inc / 2 ))  mod grid-y-inc) = 0) ]
  set vstreets streets with [ (floor ((pxcor + max-pxcor - floor(grid-x-inc / 2 )) mod grid-x-inc) = 0)]
  set hstreets streets with [ (floor ((pycor + max-pycor - floor(grid-y-inc / 2 ) ) mod grid-y-inc) = 0)]
  set intersections streets with [ (floor ((pxcor + max-pxcor - floor(grid-x-inc / 2)) mod grid-x-inc) = 0) and
                                 (floor ((pycor + max-pycor - floor(grid-y-inc / 2 ) )  mod grid-y-inc) = 0) ]
  ifelse (four-dirs?)[
    set Sstreets vstreets with [(floor ((pxcor + max-pxcor) / grid-x-inc ) mod 2) = 0]
    set Nstreets vstreets with [(floor ((pxcor + max-pxcor) / grid-x-inc ) mod 2) = 1]
    set Estreets hstreets with [(floor ((pycor + max-pycor) / grid-y-inc ) mod 2) = 1]
    set Wstreets hstreets with [(floor ((pycor + max-pycor) / grid-y-inc ) mod 2) = 0]
  ][
    set Sstreets vstreets 
    set Estreets hstreets 
  ]  
    
  ask streets[
    set street? true
    set traffic-light? false
    set green-horizontal? false
    set all-stop? false
    set was-all-stop? false
    set intersection? false
    set rule 184
    set horizontal? false
    set vertical? false
    set upstream? false
    set southbound?  false
    set eastbound?   false
    set northbound? false
    set westbound? false
    set on? false
    set was-on? false
    set monitor? false
    set greensteps 0
    set carsteps 1
    set switchsteps 0
    set mob? false
  ]
  ask hstreets [
    set horizontal? true
  ]
  ask vstreets [
    set vertical? true
  ]
  if (four-dirs?)[
    ask Wstreets [
      set westbound? true
    ]
    ask Nstreets [
      set northbound? true
    ]
  ]
  ask Estreets [
    set eastbound? true
  ]
  ask Sstreets [
    set southbound? true
  ]

  
  ask intersections[
    set intersection? true
    set switch-asap false
    if southbound?[
      ask patch-at 0  1 [ set traffic-light? true]
      ask patch-at 0 -1 [ set upstream? true]
    ]
    if eastbound?[
      ask patch-at -1 0 [ set traffic-light? true]
      ask patch-at  1 0 [ set upstream? true]
    ]
    if northbound?[
      ask patch-at 0 -1 [ set traffic-light? true]
      ask patch-at 0  1 [ set upstream? true]
    ]
    if westbound?[
      ask patch-at  1 0 [ set traffic-light? true]
      ask patch-at -1 0 [ set upstream? true]
    ]
       
  ]
  set traffic-lights streets with [traffic-light?]
  ask traffic-lights[
    set rule 252
  ]
  set upstreams streets with [upstream?]
  ask upstreams[
    set rule 136
  ]

  ask streets [extrapolate-rule]
  set street-to-monitor one-of streets with [ not intersection?]

  if any? intersections[
  
    ask intersections[
      init-lights
    ]
  
  ;  set intersection-to-monitor one-of intersections
    let px max [pxcor] of intersections
    let py max [pycor] of intersections  
    set intersection-to-monitor one-of intersections with [pxcor = px and pycor = py]
    ask intersection-to-monitor[
      set monitor? true
      ask neighbors[
        set pcolor white
      ]
    ]
    if grid-size-x >= 4 and corr-intersections-stats?[
      set intersection-to-monitor2 one-of intersections with [pxcor = (px - grid-x-inc)  and pycor = py]
      set intersection-to-monitor3 one-of intersections with [pxcor = (px - (2 * grid-x-inc))  and pycor = py]
      set intersection-to-monitor4 one-of intersections with [pxcor = (px - (3 * grid-x-inc))  and pycor = py]    
      ask intersection-to-monitor2[
        set monitor? true
        ask neighbors[
          set pcolor white
        ]
      ]
      ask intersection-to-monitor3[
        set monitor? true
        ask neighbors[
          set pcolor white
        ]
      ]
      ask intersection-to-monitor4[
        set monitor? true
        ask neighbors[
          set pcolor white
        ]
      ]
    ]
    set intersections-to-monitor intersections with [monitor?]  
  ]
  
  ask street-to-monitor[
    set monitor? true
    ask neighbors[
      set pcolor white
    ]
  ]
  
  ;;set neighbors depending on topology
  ask streets[
    if eastbound? and not (intersection? and not green-horizontal?)[
      set l patch-at -1 0  
      set r patch-at 1 0  
    ]
    if southbound? and not (intersection? and green-horizontal?)[
      set l patch-at  0 1 
      set r patch-at 0 -1
    ]
    if westbound? and not (intersection? and not green-horizontal?)[
      set l patch-at 1 0  
      set r patch-at -1 0 
    ]
    if northbound? and not (intersection? and green-horizontal?)[
      set l patch-at  0 -1
      set r patch-at 0 1 
    ]
    
    if topology = "simple Moebius"[
      let x pxcor
      let y pycor
      if pxcor = max-pxcor[
        set mob? true
        ifelse eastbound? [
          set r patch (- y + 2) max-pycor
        ][
          set l patch (- y + 2) max-pycor
        ]
      ]
      if pxcor = min-pxcor[
        set mob? true
        ifelse eastbound? [
          set l patch (- y + 2) min-pycor
        ][
          set r patch (- y + 2) min-pycor        
        ]
      ]
      if pycor = max-pycor[
        set mob? true
        ifelse southbound? [
          set l patch max-pxcor (- x + 2)
        ][
          set r patch max-pxcor (- x + 2)
        ]
      ]
      if pycor = min-pycor[
        set mob? true
        ifelse southbound? [
          set r patch min-pxcor (- x + 2)
        ][
          set l patch min-pxcor (- x + 2)
        ]
      ]

    ]
    
    if topology = "single Moebius"[;;should use even number of streets...
      let x pxcor
      let y pycor
      ifelse four-dirs? [  
        if pxcor = max-pxcor[
          set mob? true
          ifelse eastbound? [            
            set r patch x (y - grid-y-inc)         
          ][
            set l patch x (y + grid-y-inc)
          ]
        ]
        if pxcor = min-pxcor[
          set mob? true
          ifelse eastbound? [
            ifelse pycor = max [pycor] of hstreets[
              set l patch (- y + 2) min-pycor
            ][
              set l patch x (y + grid-y-inc)
            ]
          ][
            ifelse pycor = min [pycor] of hstreets[
              set r patch (- y + 2) min-pycor        
            ][
              set r patch x (y - grid-y-inc)   
            ]
          ]
        ]        
        if pycor = max-pycor[
          set mob? true
          ifelse southbound? [
            set l patch (x + grid-x-inc) y
          ][
            set r patch (x - grid-x-inc) y
          ]
        ]
        if pycor = min-pycor[
          set mob? true
          ifelse southbound? [
            ifelse pxcor = min [pxcor] of vstreets[
              set r patch min-pxcor (- x + 2)
            ][
              set r patch (x - grid-x-inc) y
            ]
          ][
            ifelse pxcor = max [pxcor] of vstreets[
              set l patch min-pxcor (- x + 2)
            ][
              set l patch (x + grid-x-inc) y
            ]
          ]
        ]
      ][;;two-dirs, only eastbound and southbound
        if pxcor = max-pxcor[
          set mob? true
          ifelse pycor = min [pycor] of hstreets[
            set r patch (- y + 2) max-pycor        
          ][
            set r patch min-pxcor (y - grid-y-inc)
          ]
        ]
        if pxcor = min-pxcor[
          set mob? true
          ifelse pycor = max [pycor] of hstreets[
            set l patch (- y + 2) min-pycor
          ][
            set l patch max-pxcor (y + grid-y-inc)
          ]
        ]        
        if pycor = max-pycor[
          set mob? true
          ifelse pxcor = max [pxcor] of vstreets[
            set l patch max-pxcor (- x + 2)
          ][
            set l patch (x + grid-x-inc) min-pycor
          ]
        ]
        if pycor = min-pycor[
          set mob? true
          ifelse pxcor = min [pxcor] of vstreets[
            set r patch min-pxcor (- x + 2)
          ][
            set r patch (x - grid-x-inc) max-pycor
          ]
        ]      
      ]

    ];;single moebius
    
    
  ]

end

to init-lists
  set flow-data []
  set car-intervals-street []
  
  if any? intersections[
    ask intersections-to-monitor[
      set switch-intervals []
      set car-intervals-intersection []
    ]
  ]
  set swI 0;;Information for intersection switches
  set ciI 0;;Information for cars at intersections
  set csI 0;;Information for cars at street
  
end

to init-lights
  set phase 0  
  if method = "marching"[
      GH true
      set switch-asap false
  ]
  if method = "green-wave"[
    set switch-asap false
    let gw-speed 1
    ;set var round ((10 * p + (pxcor / gw-speed) - (pycor  / gw-speed) - max-pycor ) mod (2 * p) )
    set var round (((pxcor / gw-speed) - (pycor  / gw-speed) ) mod (2 * p) )
    ifelse (p <= var)[
      GH false
    ][
      GH true
    ]
  ]
  if method = "SOLA"[
    set switch-asap true
    set kappa 0
  ]
  
  init-TL
end

to GH [w?]
  ifelse w?[
    set green-horizontal? true
    ask patch-at -1 0 [ set green-horizontal? true]
    ask patch-at  0 1 [ set green-horizontal? true]
    ask patch-at  1 0 [ set green-horizontal? true]
    ask patch-at 0 -1 [ set green-horizontal? true]  
  ][
    set green-horizontal? false
    ask patch-at -1 0 [ set green-horizontal? false]
    ask patch-at  0 1 [ set green-horizontal? false]
    ask patch-at  1 0 [ set green-horizontal? false]
    ask patch-at 0 -1 [ set green-horizontal? false]
  ]
end

to init-TL
  ask traffic-lights[
    ifelse green-horizontal?[
      ifelse horizontal?[
        set rule 184
      ][    
        set rule 252
      ]
    ][
      ifelse horizontal?[
        set rule 252
      ][    
        set rule 184
      ]    
    ]
    extrapolate-rule
  ]
  
  ask upstreams[
    ifelse green-horizontal?[
      ifelse horizontal?[
        set rule 184
      ][    
        set rule 136
      ]
    ][
      ifelse horizontal?[
        set rule 136
      ][    
        set rule 184
      ]    
    ]
    extrapolate-rule
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GO Procedures      ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  do-method ;; traffic lights
  ask intersections with [switch-asap and not on? and not all-stop?][
    switch-traffic-lights
  ]
  ask intersections with [all-stop?][
    second-red
  ]
  ask intersections with [not switch-asap and not all-stop? and was-all-stop?][
    second-green
  ]
;;show count intersections with [on? and was-on?]
  ask streets[  ;; keep old states
    set was-on? on?
  ]
  ask streets  ;; apply rule
    [ do-rule ]
  ask streets [  ;; color in changed cells
    color-patch 
  ]
  do-lists
  my-update-plots
  do-clock
end

to do-clock
  tick
  ;; The phase cycles from 0 to p, then starts over.
  set phase phase + 1
  if phase mod p = 0
    [ set phase 0 ]
  ask intersections [
    set greensteps (greensteps + 1)
  ]
  if any? intersections[
    ask intersections-to-monitor[
      set switchsteps (switchsteps + 1)
    ]
  ]
end

to do-rule  ;; patch procedure
  let left-on? [was-on?] of l
  let right-on? [was-on?] of r

  ;; each of these lines checks the local area and (possibly)
  ;; sets the lower cell according to the corresponding switch
  let new-value
    (iii and left-on?       and on?       and right-on?)          or
    (iio and left-on?       and on?       and (not right-on?))    or
    (ioi and left-on?       and (not on?) and right-on?)          or
    (ioo and left-on?       and (not on?) and (not right-on?))    or
    (oii and (not left-on?) and on?       and right-on?)          or
    (oio and (not left-on?) and on?       and (not right-on?))    or
    (ooi and (not left-on?) and (not on?) and right-on?)          or
    (ooo and (not left-on?) and (not on?) and (not right-on?))
  set on? new-value
end

to try-switch-traffic-lights; intersection procedure
  ifelse all-stop? [
    second-red
  ][
    ifelse on? [
      ifelse switch-asap[
        set switch-asap false
      ][
        set switch-asap true
      ]
    ][
      switch-traffic-lights
    ]
  ]
end

to switch-traffic-lights; intersection procedure
  if not on?[
    if monitor? and switchsteps > 0 [
      set switch-intervals sentence switch-intervals switchsteps
      set switchsteps 0
    ]
    set all-stop? false
    ask neighbors4 [ set all-stop? false ]
    set switch-asap false
    set green-horizontal? (not green-horizontal?)
    set greensteps 0
    set rule 184
    extrapolate-rule
    
    ifelse green-horizontal?[      
      ifelse eastbound? [
        set l patch-at -1 0  
        set r patch-at 1 0  
      ][
        set l patch-at 1 0  
        set r patch-at -1 0 
      ]
    ][
      ifelse southbound?[
        set l patch-at  0 1 
        set r patch-at 0 -1
      ][
        set l patch-at  0 -1
        set r patch-at 0 1 
      ]
    ]
    
    ask patch-at -1 0[
      ifelse green-horizontal?[
        ifelse eastbound? [
          set rule 252;;red light rule east     
        ][
          set rule 136;;red light rule west
        ]
      ][
        set rule 184;;green light rule
      ]
      extrapolate-rule
      set green-horizontal? (not green-horizontal?)
    ]
    ask patch-at 0 1[
      ifelse not green-horizontal?[
        ifelse southbound? [
          set rule 252;;red light rule south     
        ][
          set rule 136;;red light rule north
        ]
      ][
        set rule 184;;green light rule
      ]
      extrapolate-rule
      set green-horizontal? (not green-horizontal?)
    ]
    ask patch-at 1 0[
      ifelse green-horizontal?[
        ifelse eastbound? [
          set rule 136;;red light rule east
        ][
          set rule 252;;red light rule west
        ]  
      ][
        set rule 184;;green light rule
      ]
      extrapolate-rule
      set green-horizontal? (not green-horizontal?)
    ]
    ask patch-at 0 -1[
      ifelse not green-horizontal?[
        ifelse southbound? [
          set rule 136;;red light rule south    
        ][
          set rule 252;;red light rule north
        ]  
      ][
        set rule 184;;green light rule
      ]
      extrapolate-rule
      set green-horizontal? (not green-horizontal?)
    ]
  ]
end

to second-red ;intersection procedure, to set a second red light
  if monitor? and not was-all-stop? [
      set switch-intervals sentence switch-intervals switchsteps
      set switchsteps 0
  ]
  set was-all-stop? true
  ask neighbors4 [ set all-stop? true ]    
  set rule 136
  extrapolate-rule
  set greensteps 0
  ifelse green-horizontal?[
    ifelse eastbound?[
      ask patch-at -1 0[
        set rule 252
        extrapolate-rule
      ]
    ][
      ask patch-at 1 0[
        set rule 252
        extrapolate-rule
      ]
    ]  
  ][
    ifelse southbound?[
      ask patch-at 0 1[
        set rule 252
        extrapolate-rule
      ]
    ][
      ask patch-at 0 -1[
        set rule 252
        extrapolate-rule
      ]
    ]
  ]

end

to second-green ;intersection procedure, to set a second light back to green (without switching...)
  set was-all-stop? false
  ask neighbors4 [ set all-stop? false ]    
  set rule 184
  extrapolate-rule
  set greensteps 0
  if monitor? and switchsteps > 0 [
      set switch-intervals sentence switch-intervals switchsteps
      set switchsteps 0
    ]
  ifelse green-horizontal?[
    ask patch-at -1 0[
      set rule 184
      extrapolate-rule
    ]
    ask patch-at 1 0[
      set rule 184
      extrapolate-rule
    ]
  ][
    ask patch-at 0 1[
      set rule 184
      extrapolate-rule
    ]
    ask patch-at 0 -1[
      set rule 184
      extrapolate-rule
    ]
  ]

end

to do-method
  if method = "marching" [march]
  if method = "green-wave" [gw]
  if method = "SOLA" [SOLA]  
end

to march
  if (ticks mod p) = 0[
    ask intersections[
      try-switch-traffic-lights
    ]
  ]
end

to gw
  let gw-speed 1
  ask intersections[
;    if (phase = (round (p + (pxcor / gw-speed) - (pycor  / gw-speed) - max-pycor) mod p))[
    if (phase = (round ( (pxcor / gw-speed) - (pycor  / gw-speed)) mod p))[
      try-switch-traffic-lights
    ]
  ]
end

to SOLA
  ask intersections [
    let cars 0
    let cars2 0
    let blockahead false
    let blockahead2 false
    let i 0
    
    ifelse rule1?[
      set r1 false
    ][
      set r1 true
    ]
    ifelse rule2?[
      set r2 false
    ][
      set r2 true
    ]
    ifelse rule3?[
      set r3 false
    ][
      set r3 true
    ]
    set r4 false
    set r5 false
    
    ifelse (green-horizontal?)
      [;;red light coming from north or south
      set i 1
      set cars 0
       while [i < sensor-distance]
       [
         ifelse southbound?[
           ask patch-at 0 i[
             if on? [
               set cars (cars + 1)
             ]
           ]
         ][
           ask patch-at 0 (- i)[
             if on? [
               set cars (cars + 1)
             ]
           ]
         ]
         set i (i + 1)
       ]
       set kappa (kappa + cars)
  
       set i 1
       set cars 0
       while [i < keep-platoon]
       [
         ifelse eastbound?[
           ask patch-at (- i) 0 [
             if on? [
               set cars (cars + 1)
             ]
           ]
         ][
           ask patch-at (i) 0 [
             if on? [
               set cars (cars + 1)
             ]
           ]
         ]
         set i (i + 1)
       ]
     
       ;if nobody's coming, switch to green! rule 4
       set i 1
       set cars2 0
       while [i < sensor-distance]
       [
         ifelse eastbound?[
           ask patch-at (- i) 0 [
             if on? [
               set cars2 (cars2 + 1)
             ]
           ]
         ][
           ask patch-at (i) 0 [
             if on? [
               set cars2 (cars2 + 1)
             ]
           ]
         ]
         set i (i + 1)
       ]
       
       ;if block ahead of green light, turn it to red... rule 5
       set blockahead false
       ifelse eastbound?[
         ask patch-at cut-ahead 0 [
           if on? and was-on?[
             set blockahead true
           ]
         ]
       ][
         ask patch-at (- cut-ahead) 0 [
           if on? and  was-on?[
             set blockahead true
           ]
         ]
       ]
                  
      
       ifelse southbound?[
         ask patch-at 0 (- cut-ahead) [
           if on? and was-on?[
             set blockahead2 true;;initialized as false on begining of procedure
           ]
         ]
       ][
         ask patch-at 0 cut-ahead [
           if on? and was-on?[
             set blockahead2 true
           ]
         ]
       ]
       ifelse (blockahead2) and rule6? [;; both directions blocked (see below)
         set all-stop? true
       ][
         set all-stop? false
       ]       
     
       
       if (kappa > tolerance) [;rule 1
         set r1 true
       ]
       if (greensteps > mingreen)[;rule 2
         set r2 true
       ]
       if ((0 = cars) or ((cars >= cut-platoon)))[; on street with green light ;rule 3
         set r3 true
       ]
       if ((cars2 = 0) and (kappa >= 1) and rule4?) [;rule 4
         set r4 true
       ]
       ifelse (blockahead) and rule5? [;rule 5
         set r5 true
       ][
         set all-stop? false ;; all stop only when both streets are blocked
       ]  
                 
    ][;;red light from west or east
      set i 1
      set cars 0
      while [i < sensor-distance]
      [
        ifelse eastbound?[
           ask patch-at (- i) 0 [
             if on? [
               set cars (cars + 1)
             ]
           ]
         ][
           ask patch-at (i) 0 [
             if on? [
               set cars (cars + 1)
             ]
           ]
         ]
        set i (i + 1)
      ]
      set kappa (kappa + cars)    
      
      set i 1
      set cars 0
      while [i < keep-platoon]
      [
        ifelse southbound?[
           ask patch-at 0 i[
             if on? [
               set cars (cars + 1)
             ]
           ]
         ][
           ask patch-at 0 (- i)[
             if on? [
               set cars (cars + 1)
             ]
           ]
         ]
        set i (i + 1)
      ]
    
      ;if nobody's coming, switch to green!
      set i 1
      set cars2 0
      while [i < sensor-distance]
      [
        ifelse southbound?[
           ask patch-at 0 i[
             if on? [
               set cars2 (cars2 + 1)
             ]
           ]
         ][
           ask patch-at 0 (- i)[
             if on? [
               set cars2 (cars2 + 1)
             ]
           ]
         ]
         set i (i + 1)
      ]
    
      ;if block ahead of green light, turn it to red...
      set blockahead false
      ifelse southbound?[
         ask patch-at 0 (- cut-ahead) [
           if on? and was-on?[
             set blockahead true
           ]
         ]
       ][
         ask patch-at 0 cut-ahead [
           if on? and was-on?[
             set blockahead true
           ]
         ]
       ]
  
       ifelse eastbound?[
         ask patch-at cut-ahead 0 [
           if on? and was-on?[
             set blockahead2 true;;initialized as false on begining of procedure
           ]
         ]
       ][
         ask patch-at (- cut-ahead) 0 [
           if on? and  was-on?[
             set blockahead2 true
           ]
         ]
       ]
       ifelse (blockahead2) and rule6? [;; both directions blocked
         set all-stop? true
       ][
         set all-stop? false
       ]       
       
       
       
       if (kappa > tolerance) [
         set r1 true
       ]
       if (greensteps > mingreen) [
         set r2 true
       ]
       if ((0 = cars) or ((cars >= cut-platoon)))[; on street with green light
         set r3 true
       ]
       if ((cars2 = 0) and (kappa >= 1) and rule4?)  [
         set r4 true
       ]
       ifelse (blockahead) and rule5?[
         set r5 true
       ][
         set all-stop? false ;; all stop only when both streets are blocked
       ]       
              
    ];end red light horizontal

    if  ((r5) or
      (r4 and not blockahead2) or
      (r1 and r2 and r3 and not blockahead2 and (rule1? or rule2? or rule3?)))
    [     
       set kappa 0
       try-switch-traffic-lights                                                                  
    ] 

  ] ;; ask intersections
  
  
  
                            

end

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Utility Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

to color-patch  ;;patch procedure
  ifelse traffic-light?[
    ifelse horizontal?[
      ifelse green-horizontal? and (not all-stop?)
        [ set pcolor green ]
        [ set pcolor red ] 
    ][
      ifelse (not green-horizontal?) and (not all-stop?)
        [ set pcolor green ]
        [ set pcolor red ]     
    ]
  ][;street
    ifelse on?
      [ 
        ifelse was-on?[
          set pcolor foreground - 50 
        ][
          set pcolor foreground 
        ]
      ]
      [ set pcolor background ]   
  ]
end

to-report bindigit [number power-of-two]
  ifelse (power-of-two = 0)
    [ report floor number mod 2 ]
    [ report bindigit (floor number / 2) (power-of-two - 1) ]
end

to extrapolate-rule
  ;; set the switches based on the slider
  set ooo ((bindigit rule 0) = 1)
  set ooi ((bindigit rule 1) = 1)
  set oio ((bindigit rule 2) = 1)
  set oii ((bindigit rule 3) = 1)
  set ioo ((bindigit rule 4) = 1)
  set ioi ((bindigit rule 5) = 1)
  set iio ((bindigit rule 6) = 1)
  set iii ((bindigit rule 7) = 1)
end

to-report calculate-rule
  ;; set the slider based on the switches
  let result 0
  if ooo [ set result result +   1 ]
  if ooi [ set result result +   2 ]
  if oio [ set result result +   4 ]
  if oii [ set result result +   8 ]
  if ioo [ set result result +  16 ]
  if ioi [ set result result +  32 ]
  if iio [ set result result +  64 ]
  if iii [ set result result + 128 ]
  report result
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Plotting Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to do-lists
  set #cars-old #cars
  set #cars count streets with [on?]
  if #cars != #cars-old[
    print "WARNING: Vehicles were not conserved!"
  ]
  set flow (count streets with [on? and not was-on?]) / #cars
  set flow-data sentence flow-data flow
  if any? intersections[
    ask intersections-to-monitor[
      ifelse (not on? and was-on?) [;;car moved out of here
        set car-intervals-intersection sentence car-intervals-intersection carsteps
        set carsteps 1
      ][
        set carsteps (carsteps + 1)
      ]
    ]
  ]
  ask street-to-monitor[
    ifelse (not on? and was-on?) [;;car moved out of here
      set car-intervals-street sentence car-intervals-street carsteps
      set carsteps 1
    ][
      set carsteps (carsteps + 1)
    ]
  ]
  
  if (ticks mod info-update = info-update - 1)[;;update Information measures
    if any? intersections[
      if (length [switch-intervals] of intersection-to-monitor > 2)[
        set swI shannon ([switch-intervals] of intersection-to-monitor)
      ]    
      if (length [car-intervals-intersection] of intersection-to-monitor > 2)[
        set ciI shannon ([car-intervals-intersection] of intersection-to-monitor)
      ]
    ]
    if (length car-intervals-street > 2)[
      set csI shannon car-intervals-street
    ]
  ]
end

to my-update-plots
  if plots?[
    set-current-plot "Velocity"
    set-current-plot-pen "default"
    plotxy ticks  flow
    set-current-plot-pen "mean"
    plotxy ticks  mean flow-data

    set-current-plot "Flux"
    set-current-plot-pen "default"
    plotxy ticks  flow * density / 100
    set-current-plot-pen "mean"
    plotxy ticks  mean flow-data * density / 100

    if any? intersections[
      set-current-plot "Switch Intervals"
      set-current-plot-pen "default"
      histogram [switch-intervals] of intersection-to-monitor
  
      set-current-plot "Car Intervals @ Intersection"
      set-current-plot-pen "default"
      histogram [car-intervals-intersection] of intersection-to-monitor
    ]
    
    set-current-plot "Car Intervals @ Street"
    set-current-plot-pen "default"
    histogram car-intervals-street

  ]
end

to-report norm [d] ;;normalizes a list of data d to base set in Ibase slider
  let n []
  ifelse (max d - min d) > 0[
    let i 0
    while [i < length d][
      set n lput (floor (0.99999999 * Ibase * ((item i d) - min d) / (max d - min d))) n
      set i (i + 1)
    ]
  ][;; if all values are equal, then set all of them in the first category
    let i 0
    while [i < length d][
      set n lput 0 n
      set i (i + 1)
    ]
  
  ]  
  report n
end

to-report shannon [X] ;;calculates Shannon Information for list X using Ibase
  set X norm X ;; normalize data
  let H 0
  let pr [] ;;probabilitylist
  let i 0
  while [i < Ibase][
    set pr lput 0 pr ;; fill in pr list with zeros
    set i (i + 1)
  ]
  set i 0
  while [i < length X][
    set pr replace-item (item i X) pr ((item (item i X) pr) + 1)
    set i (i + 1)
  ]
  set i 0
  while [i < Ibase][
    set pr replace-item i pr ((item i pr) / length X) ;;normalize probabilities
    if (item i pr) > 0[
      set H (H + ((item i pr) * log (item i pr) 2))
    ]
    set i (i + 1)
  ]
  report -1 * H / (log Ibase 2)  ;; return H normalized to [0,1]
end

;Original model copyright:

; *** NetLogo 4.0.4 Model Copyright Notice ***
;
; This model was created as part of the project: CONNECTED MATHEMATICS:
; MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL
; MODELS (OBPML).  The project gratefully acknowledges the support of the
; National Science Foundation (Applications of Advanced Technologies
; Program) -- grant numbers RED #9552950 and REC #9632612.
;
; Copyright 1998 by Uri Wilensky.  All rights reserved.
;
; Permission to use, modify or redistribute this model is hereby granted,
; provided that both of the following requirements are followed:
; a) this copyright notice is included.
; b) this model will not be redistributed for profit without permission
;    from Uri Wilensky.
; Contact Uri Wilensky for appropriate licenses for redistribution for
; profit.
;
; This model was converted to NetLogo as part of the projects:
; PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING
; IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT.
; The project gratefully acknowledges the support of the
; National Science Foundation (REPP & ROLE programs) --
; grant numbers REC #9814682 and REC-0126227.
; Converted from StarLogoT to NetLogo, 2001.
;
; To refer to this model in academic publications, please use:
; Wilensky, U. (1998).  NetLogo CA 1D Elementary model.
; http://ccl.northwestern.edu/netlogo/models/CA1DElementary.
; Center for Connected Learning and Computer-Based Modeling,
; Northwestern University, Evanston, IL.
;
; In other publications, please use:
; Copyright 1998 Uri Wilensky.  All rights reserved.
; See http://ccl.northwestern.edu/netlogo/models/CA1DElementary
; for terms of use.
;
; *** End of NetLogo 4.0.4 Model Copyright Notice ***
@#$#@#$#@
GRAPHICS-WINDOW
270
10
1080
841
-1
-1
5.0
1
10
1
1
1
0
1
1
1
-80
79
-80
79
1
1
1
ticks
30.0

BUTTON
41
146
114
180
setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

TEXTBOX
281
845
371
863
Colors:
11
0.0
0

SLIDER
125
49
231
82
density
density
1
100.0
8
1
1
%
HORIZONTAL

BUTTON
119
148
190
181
NIL
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

INPUTBOX
282
864
402
924
foreground
94
1
0
Color

INPUTBOX
407
864
523
924
background
1
1
0
Color

SLIDER
5
260
120
293
p
p
1
160
80
1
1
timesteps
HORIZONTAL

SLIDER
3
13
120
46
grid-size-x
grid-size-x
0
16
10
1
1
NIL
HORIZONTAL

SLIDER
121
13
238
46
grid-size-y
grid-size-y
1
16
10
1
1
NIL
HORIZONTAL

MONITOR
31
94
88
139
cars
#cars
17
1
11

PLOT
3
471
264
657
Velocity
timesteps
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" ""
"mean" 1.0 0 -16777216 true "" ""

SLIDER
129
88
228
121
%vertical
%vertical
0
100
50
1
1
NIL
HORIZONTAL

CHOOSER
6
184
114
229
method
method
"marching" "green-wave" "SOLA"
1

SWITCH
10
49
119
82
four-dirs?
four-dirs?
0
1
-1000

SLIDER
2
320
172
353
sensor-distance
sensor-distance
0
20
10
1
1
patches
HORIZONTAL

SLIDER
3
353
141
386
tolerance
tolerance
0
300
40
1
1
cars * ts
HORIZONTAL

SLIDER
0
388
148
421
keep-platoon
keep-platoon
0
10
5
1
1
patches
HORIZONTAL

SLIDER
147
388
269
421
cut-platoon
cut-platoon
0
10
2
1
1
cars
HORIZONTAL

SLIDER
0
423
148
456
cut-ahead
cut-ahead
0
10
2
1
1
patches
HORIZONTAL

SLIDER
142
352
250
385
mingreen
mingreen
0
60
10
1
1
ts
HORIZONTAL

TEXTBOX
5
307
155
325
SOLA\n
11
0.0
1

TEXTBOX
8
245
158
263
Green wave & marching\n
11
0.0
1

SWITCH
9
849
112
882
plots?
plots?
0
1
-1000

PLOT
3
658
264
844
Flux
NIL
NIL
0.0
10.0
0.0
0.5
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" ""
"mean" 1.0 0 -16777216 true "" ""

BUTTON
198
149
261
182
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1092
16
1518
215
Switch Intervals
NIL
NIL
0.0
161.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

PLOT
1092
218
1519
416
Car Intervals @ Intersection
NIL
NIL
0.0
50.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

PLOT
1093
421
1521
618
Car Intervals @ Street
NIL
NIL
0.0
50.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

CHOOSER
140
194
232
239
topology
topology
"cyclic" "simple Moebius" "single Moebius"
0

BUTTON
723
853
802
886
platoon
ask streets with [pxcor < -50 and pycor = min [pycor] of hstreets] [\n set on? true\n color-patch\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1093
620
1196
653
rule1?
rule1?
0
1
-1000

SWITCH
1093
653
1196
686
rule2?
rule2?
0
1
-1000

SWITCH
1093
686
1196
719
rule3?
rule3?
0
1
-1000

SWITCH
1093
719
1196
752
rule4?
rule4?
0
1
-1000

SWITCH
1093
752
1196
785
rule5?
rule5?
0
1
-1000

SWITCH
1093
785
1196
818
rule6?
rule6?
0
1
-1000

SLIDER
1273
641
1402
674
info-update
info-update
1
1000
100
1
1
ts
HORIZONTAL

SLIDER
1274
681
1404
714
Ibase
Ibase
0
20
20
1
1
NIL
HORIZONTAL

MONITOR
1548
41
1676
86
E (switch intervals)
swI
17
1
11

MONITOR
1548
87
1676
132
S (switch intervals)
1 - swI
17
1
11

MONITOR
1548
133
1677
178
C (switch intervals)
4 * swI * (1 - swI)
17
1
11

MONITOR
1550
229
1750
274
E (car intervals @ intersection)
ciI
17
1
11

MONITOR
1550
275
1750
320
S (car intervals @ intersection)
1 - ciI
17
1
11

MONITOR
1550
322
1752
367
C (car intervals @ intersection)
4 * ciI * (1 - ciI)
17
1
11

MONITOR
1556
442
1717
487
E (car intervals @ street)
csI
17
1
11

MONITOR
1556
489
1718
534
S (car intervals @ street)
1 - csI
17
1
11

MONITOR
1556
536
1718
581
C (car intervals @ street)
4 * csI * (1 - csI)
17
1
11

BUTTON
1227
734
1310
767
NIL
init-lists
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## CHANGELOG

1.10	11/05/16	can do single street again...  
1.09	10/07/26	fixed miniissue for single rules...  
1.08	10/07/14	added ruleX? switches  
1.07	10/03/21	four intersections to monitor (hidden)  
1.06	10/03/21	fixed bugs in moebius topos  
1.05	10/03/10	topologies: single moebius street  
1.04	10/03/09	moebius boundaries, moved assignation of neighbors to setup  
1.03	10/02/03	minor bug for car-intervals, NetLogo 4.1.  
1.02	09/12/17	minor bug for switch-intervals  
1.01	09/12/17	Added 3 histograms (for time series)  
1.00	09/12/15	Stable version, used for first paper...  
0.22	09/07/10	Simplified GW equations, thanks to David Rosenblueth  
0.21	09/06/29	Fixed minor GW init bug, didn't affect results  
0.20	09/06/26	Fixed more minor SOLA bugs (now no intersection get blocked)  
0.19	09/06/25	Fixed minor SOLA bugs of new rule and rule 5 (was-on? and on?)  
0.18	09/06/23	Added all-stopped for SOLA, works better for high densities!
			Fixed traffic light init bug  
0.17	09/06/22	Added Flux plot (old flow -> velocity)  
0.16	09/06/18	Different colors for moving and stopped vehicles  
0.15	09/06/18	Improved density initialization (closer to reality)  
0.14	09/06/02	Added Information  
0.13	09/05/08	restored Rule 5 AND Rule 2 
				(good for lower densities, 0.12 bit better for higher)  
0.12	09/05/07	moved Rule 5 back to top (no AND Rule 2)  
0.11	09/04/28	fixed bug at try-switch-traffic-lights...  
0.10	09/04/17	checks at setup that there is at least one car...  
0.09	09/04/16	possible to have no vertical streets, i.e. no intersections  
0.08	09/04/15	ready for Java sims  
0.07	09/04/01	SOLA  
0.06	09/03/01(CDG)	Four dirs...  
0.05	09/02/24	Added green-wave...  
0.04	09/02/23	Fixed turings, added %vertical slider

## TODO

## WHAT IS IT?

This is model of city traffic based on elementary cellular automata (ECA) .  
More info at http://turing.iimas.unam.mx/~cgg/

## HOW TO USE IT

Click on "Setup" and then on "Go" or "Step". The controls above these buttons should be set before "Setup", the others can be changed anytime.

GRID-SIZE-X and GRID-SIZE-Y determine how many streets will be with each orientation (vertical and horizontal). Use GRID-SIZE-X=0 for freeway model (Rule 184), i.e. no intersections

FOUR-DIRS? If true, streets flow in four directions (alternating). If false, only south and eastboud.

DENSITY. Determines probabilistically how many cells are occupied by vehicles.

%VERTICAL Determines probabilistically the percentage of cars on vertical streets (complementary to horizontal ones)

TOPOLOGY. Choose boundary conditions:  
"cyclic": periodic boundaries  
"simple Moebius": horizontal roads continue as vertical roads and vice versa, i.e. roads intersect with themselves once. Thus, GRID-SIZE-X should be equal to GRID-SIZE-Y.  
"single Moebius": whole city is a single self-intersecting street...

METHOD. Choose between following methods:  
"Marching": all lights march in step, either vertical or horizontal  
"Green-wave": Lights are synchronized so that vehicels flowing eastbound or southbound would not need to stop (at a flow speed of 1)

The next parameter affects the marching or green wave methods

P Duration of a green light, i.e. half a period (T/2). To avoid stopping of vehicels, set this equal to half the length of the street or equal to a factor of half the length of the street.

The following parameters affect the self-organizing method. See paper for a description.

SENSOR-DISTANCE (d) 

TOLERANCE (n)

MINGREEN (t_min)

KEEP-PLATOON (m)

CUT-PLATOON (r)

CUT-AHEAD (e)

## THINGS TO NOTICE

The Velocity plot shows the percentage of vehicles moving, i.e. if v=1, no vehicle stops, and if v=0, all vehicles are stopped.

The Flux plot shows the velocity multiplied by the density. In the rule 184 model of highway traffic (i.e. no intersections, grid-size-x = 0), the maximum possible flux is $J=0.5$, at a density $\rho=0.5$. This is because vehicles need at least one cell between them to move. If there are less vehicles, the flux will be lower, since there is no movement in free space. If there are more vehicles, then the flux will also be lower, since stopped vehicles do not move.

## THINGS TO TRY

The green wave method works fine for only two directions (set FOUR-DIRS? to false). However, when vehicles flow in four directions (and there are more than two streets in any orientation), the performance is relatively bad, because vehicles going opposite to the green wave face anti-correlated lights.

The self-organizing mehtod can achieve free flow in four directions for low densities.

At which densities each method reaches a gridlock (flow=0)?

See how performance varies as more streets are added (for different methods).

## CREDITS AND REFERENCES

Based on:  Wilensky, U. (1998).  NetLogo CA 1D Elementary model.  http://ccl.northwestern.edu/netlogo/models/CA1DElementary.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

About ECA:  
http://mathworld.wolfram.com/ElementaryCellularAutomaton.html  
http://en.wikipedia.org/wiki/Cellular_automata
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.3
@#$#@#$#@
setup-random repeat world-height - 1 [ go ]
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