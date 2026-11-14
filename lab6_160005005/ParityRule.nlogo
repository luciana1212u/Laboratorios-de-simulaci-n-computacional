;; =====================================================================
;;  Autómata celular de la REGLA DE PARIDAD (Parity Rule)
;;  Laboratorio 5 - Simulación Computacional - UNILLANOS
;;  Diego Alejandro Machado Tovar
;;
;;  Regla (Fredkin / Chopard & Droz):
;;     s(t+1) = s_N XOR s_E XOR s_S XOR s_W
;;  Es decir, el nuevo estado de una celda es la suma módulo 2 de los
;;  estados de sus 4 vecinos de von Neumann. Opcionalmente se puede usar
;;  la vecindad de Moore (8 vecinos) y/o incluir la propia celda.
;; =====================================================================

globals [
  initial-live      ;; número de celdas vivas al inicio
]

patches-own [
  state             ;; 0 = muerta, 1 = viva
  new-state         ;; estado calculado para el siguiente paso (actualización síncrona)
]

to setup
  clear-all
  ask patches [ set state 0 ]
  if initial-pattern = "una celda" [
    ask patch 0 0 [ set state 1 ]
  ]
  if initial-pattern = "cuadrado 3x3" [
    ask patches with [abs pxcor <= 1 and abs pycor <= 1] [ set state 1 ]
  ]
  if initial-pattern = "letra L" [
    ask patches with [pxcor = -2 and pycor >= -3 and pycor <= 3] [ set state 1 ]
    ask patches with [pycor = -3 and pxcor >= -2 and pxcor <= 1] [ set state 1 ]
  ]
  if initial-pattern = "cruz" [
    ask patches with [(pxcor = 0 and abs pycor <= 2) or (pycor = 0 and abs pxcor <= 2)] [ set state 1 ]
  ]
  if initial-pattern = "aleatorio centro" [
    ask patches with [abs pxcor <= 5 and abs pycor <= 5] [
      if random-float 100 < density [ set state 1 ]
    ]
  ]
  if initial-pattern = "aleatorio total" [
    ask patches [ if random-float 100 < density [ set state 1 ] ]
  ]
  set initial-live count patches with [state = 1]
  recolor
  reset-ticks
end

to go
  ;; 1) cada celda calcula su nuevo estado con la regla de paridad
  ask patches [
    let vecinos ifelse-value moore? [ neighbors ] [ neighbors4 ]
    let s sum [state] of vecinos
    if include-self? [ set s s + state ]
    set new-state s mod 2
  ]
  ;; 2) actualización síncrona de todas las celdas
  ask patches [ set state new-state ]
  recolor
  tick
end

to recolor
  ask patches [
    set pcolor ifelse-value (state = 1) [ cell-color ] [ black ]
  ]
end

;; Permite dibujar / borrar celdas con el ratón antes de iniciar
to draw-cells
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      set state 1 - state
      recolor
    ]
    display
    wait 0.15
  ]
end

;; Reporta si el número de iteraciones es una potencia de 2
;; (en esos instantes el patrón inicial aparece replicado)
to-report potencia-de-2?
  if ticks = 0 [ report false ]
  let n ticks
  while [n mod 2 = 0] [ set n n / 2 ]
  report n = 1
end
@#$#@#$#@
GRAPHICS-WINDOW
230
10
642
423
-1
-1
4.0
1
10
1
1
1
0
1
1
1
-50
50
-50
50
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
S
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
G
NIL
NIL
0

BUTTON
15
55
105
88
paso
go
NIL
1
T
OBSERVER
NIL
P
NIL
NIL
0

BUTTON
115
55
205
88
dibujar
draw-cells
T
1
T
OBSERVER
NIL
D
NIL
NIL
1

CHOOSER
15
100
205
145
initial-pattern
initial-pattern
"una celda" "cuadrado 3x3" "letra L" "cruz" "aleatorio centro" "aleatorio total"
2

SLIDER
15
155
205
188
density
density
1
100
30.0
1
1
%
HORIZONTAL

SWITCH
15
195
205
228
moore?
moore?
1
1
-1000

SWITCH
15
235
205
268
include-self?
include-self?
1
1
-1000

SLIDER
15
275
205
308
cell-color
cell-color
5
135
45.0
10
1
NIL
HORIZONTAL

MONITOR
15
320
110
365
celdas vivas
count patches with [state = 1]
0
1
11

MONITOR
115
320
205
365
¿t = 2^n?
potencia-de-2?
0
1
11

PLOT
655
10
925
230
Celdas vivas vs tiempo
tiempo
celdas vivas
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"vivas" 1.0 0 -2674135 true "" "plot count patches with [state = 1]"

TEXTBOX
655
245
925
420
Regla de paridad (vecindad de von Neumann):\ns(t+1) = N xor E xor S xor W\n\nCon moore? = Off e include-self? = Off se obtiene la regla clásica vista en clase. En t = 2, 4, 8, 16, 32... el patrón inicial aparece copiado 4 veces (auto-replicación), desplazado 2^n celdas en cada dirección.
11
0.0
1

@#$#@#$#@
## ¿QUÉ ES?

Autómata celular bidimensional con la **regla de paridad** (*parity rule*). Cada celda tiene dos estados (0 = muerta, 1 = viva). En cada paso, todas las celdas se actualizan de forma síncrona y el nuevo estado de una celda es la suma módulo 2 (XOR) de los estados de sus cuatro vecinos de von Neumann (norte, este, sur, oeste):

s(t+1) = s_N ⊕ s_E ⊕ s_S ⊕ s_W

## CÓMO FUNCIONA

1. Cada parche suma los estados de sus vecinos (`neighbors4`, o `neighbors` si `moore?` está activo).
2. Si `include-self?` está activo, se suma también el estado propio.
3. El nuevo estado es la suma `mod 2`.
4. Después de que todos calculan, todos se actualizan a la vez (regla síncrona).

El mundo es toroidal (bordes periódicos).

## CÓMO USARLO

- Elija un patrón en `initial-pattern` y presione **setup**.
- **go** ejecuta continuamente; **paso** ejecuta una sola iteración.
- **dibujar** permite activar/desactivar celdas con el ratón.
- El monitor **¿t = 2^n?** indica cuándo el número de pasos es potencia de 2.

## COSAS A NOTAR

La regla es lineal (aditiva módulo 2). Por eso cualquier patrón inicial se **auto-replica**: en t = 2^n el patrón original aparece copiado en 4 posiciones, desplazadas 2^n celdas al norte, sur, este y oeste. Entre esas potencias se forman figuras fractales tipo Sierpinski.

## CRÉDITOS

Implementación para el Laboratorio 5 de Simulación Computacional (UNILLANOS). Regla basada en B. Chopard y M. Droz, *Cellular Automata Modeling of Physical Systems*, y la presentación *Cellular Automata* del curso.
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
