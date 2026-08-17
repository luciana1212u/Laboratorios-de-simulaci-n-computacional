# -*- coding: utf-8 -*-
"""Confidence intervals - completo (20 y 200 clientes)

Adaptado del notebook original de la guia:
    https://colab.research.google.com/drive/1tftZK8BjLabvrzi8kblp3EjSfeLnFIub
"""

import numpy as np
from scipy import stats
from IPython.display import display, Markdown

# 1) Datos de las 10 corridas (runs)

runs_20 = {
    "Average time in system":              [4.05, 4.7, 5.15, 4.2, 4.3, 4.55, 4.25, 4.0, 5.05, 3.95],
    "Percent idle time":                   [43, 33, 29,42 , 34, 27, 39, 33, 18, 36],
    "Average waiting time per customer":   [0.9, 1.2, 1.4, 0.4, 0.85, 0.55, 0.75, 0.4, 1.8, 0.55],
    "Fraction having to wait":             [0.25, 0.3, 0.45, 0.15, 0.35, 0.3, 0.35, 0.2, 0.6, 0.2],
    "Average waiting time of those who waited": [3.6, 4.0, 3.11111, 2.666666667, 2.428571429, 1.833333333, 2.142857143, 2.0, 3.0, 2.75],
}

runs_200 = {
    "Average time in system":              [5.375, 5.145, 5.055, 4.55, 4.635, 4.435, 5.06, 4.81, 4.91, 4.62],
    "Percent idle time":                   [37, 32, 35, 39, 37, 40, 35, 35, 38, 37],
    "Average waiting time per customer":   [1.75, 1.5, 1.465, 1.135, 1.05, 0.935, 1.445, 1.195, 1.42, 1.13],
    "Fraction having to wait":             [0.365, 0.375, 0.36, 0.355, 0.335, 0.305, 0.4, 0.395, 0.35, 0.37],
    "Average waiting time of those who waited": [4.79452055, 4.0, 4.06944444, 3.1971831, 3.13432836, 3.06557377, 3.6125, 3.02531646, 4.05714286, 3.05405405],
}

datasets = {
    "20 clientes": runs_20,
    "200 clientes": runs_200,
}

confidences = [0.95, 0.99]  # 95% y 99% de confianza



# 2)logica del script 

def confidence_interval(M, confidence, label=""):
    print(M)
    reps = len(M)

    print("Rep.\tValor")
    for i in range(0, len(M)):
        print("%d\t%g" % (i + 1, M[i]), sep=' ', end='\n')

    alpha = 1 - confidence
    confidence_pct = confidence * 100

    mean = np.mean(M)
    var = np.var(M, ddof=1)
    desv = np.sqrt(var)

    tval = stats.t.ppf(1 - (alpha / 2), reps - 1)
    hval = tval * (desv / np.sqrt(reps))

    display(Markdown(
        rf"""
### {label} — {confidence_pct:.0f}% de confianza

${confidence_pct:.0f}\%$ confidence

$\bar{{X}} = {mean}$

$S = {desv}$

$t_{{n-1,1-\frac{{\alpha}}{2}}} = t_{{{reps-1},{1-alpha/2}}} ={tval}$

$h = {hval}$

Intervalo de confianza : $C.I. = (\bar{{X}}-h , \bar{{X}} + h) = ({mean-hval},{mean+hval})$

---
"""))

    return {
        "n": reps, "mean": mean, "std": desv, "t": tval, "h": hval,
        "ci_low": mean - hval, "ci_high": mean + hval,
    }


# ---------------------------------------------------------------------------
# 3) Recorrer las 5 medidas x 2 escenarios x 2 niveles de confianza.
# ---------------------------------------------------------------------------

resultados = {}

for escenario, medidas in datasets.items():
    resultados[escenario] = {}
    for nombre_medida, valores in medidas.items():
        resultados[escenario][nombre_medida] = {}
        for conf in confidences:
            etiqueta = f"{escenario} — {nombre_medida}"
            res = confidence_interval(valores, conf, label=etiqueta)
            resultados[escenario][nombre_medida][conf] = res


# ---------------------------------------------------------------------------
# 4) Tabla resumen final (media, desviacion estandar, half-width e IC)
#    para las 20 combinaciones.
# ---------------------------------------------------------------------------

print("\n\n===== RESUMEN =====")
print(f"{'Escenario':<14}{'Medida':<32}{'Conf.':<7}{'Media':>10}{'Std':>10}{'Half-width':>12}{'IC bajo':>10}{'IC alto':>10}")
for escenario, medidas in resultados.items():
    for nombre_medida, por_conf in medidas.items():
        for conf, r in por_conf.items():
            print(f"{escenario:<14}{nombre_medida:<32}{int(conf*100):<7}{r['mean']:>10.4f}{r['std']:>10.4f}{r['h']:>12.4f}{r['ci_low']:>10.4f}{r['ci_high']:>10.4f}")