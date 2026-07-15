# -*- coding: utf-8 -*-
# Mini-backtest 2026 (rondas disputadas con datos OpenF1): compara configuraciones
# de pesos del motor de GP Fantasy Advisor prediciendo cada carrera solo con datos
# anteriores. Metrica: correlacion de Spearman prediccion vs resultado real.
import math
from itertools import product

GRID = 22
TEAMS = {1:'mclaren',3:'redbull',5:'audi',6:'redbull',10:'alpine',11:'cadillac',
         12:'mercedes',14:'aston',16:'ferrari',18:'aston',23:'williams',27:'audi',
         30:'rbulls',31:'haas',41:'rbulls',43:'alpine',44:'ferrari',55:'williams',
         63:'mercedes',77:'cadillac',81:'mclaren',87:'haas'}
NAMES = {1:'NOR',3:'VER',5:'BOR',6:'HAD',10:'GAS',11:'PER',12:'ANT',14:'ALO',16:'LEC',
         18:'STR',23:'ALB',27:'HUL',30:'LAW',31:'OCO',41:'LIN',43:'COL',44:'HAM',
         55:'SAI',63:'RUS',77:'BOT',81:'PIA',87:'BEA'}

# Carreras: (ronda, clasificados en orden, dnf sin clasificar, dns)
# dnf_clasificados: pilotos clasificados pero con bandera dnf (cuentan para riesgo)
RACES = [
 (2, [12,63,44,16,87,10,30,6,55,43,27,41,77,31,11], [3,14,18], [81,1,5,23], []),
 (3, [12,81,16,63,1,44,10,3,30,31,27,6,5,41,55,43,11,14,77,23], [18,87], [], []),
 (4, [12,1,81,63,3,44,43,16,55,23,87,5,31,41,14,11,18,77], [27,30,10,6], [], []),
 (5, [12,44,3,16,6,43,30,10,55,87,81,27,5,31,18,77], [11,1,63,14,23], [41], []),
 (7, [44,63,1,3,81,6,10,30,41,43,5,55,31,11,16,12,87], [23,14,27,77,18], [], [16,12,87]),
 (8, [63,3,12,81,44,6,1,16,30,41,5,27,10,87,43,31,23,14], [18,55,11,77], [], []),
]
# Qualis: ronda -> orden de posiciones
QUALI = {
 2: [12,63,44,16,81,1,10,3,6,87,27,43,31,30,41,5,55,23,14,77,18,11],
 3: [12,63,81,16,1,44,10,6,5,41,3,31,27,30,43,55,23,87,11,77,14,18],
 4: [12,3,16,1,63,44,81,43,10,27,30,87,55,31,23,41,14,18,77,11,5,6],
 5: [63,12,1,81,44,3,6,16,41,43,27,30,5,10,55,87,31,23,14,11,18,77],
 8: [63,16,44,12,3,1,81,6,30,41,10,5,87,27,31,43,55,23,11,77,14,18],
}
# Mejor vuelta de quali (s) por piloto, para la faceta vuelta_rapida (gap %)
QBEST = {
 2: {12:92.064,63:92.286,44:92.415,16:92.428,81:92.55,1:92.608,10:92.873,3:93.002,
     6:93.121,87:93.197,27:93.354,43:93.357,31:93.538,30:93.765,41:93.784,5:93.549,
     55:94.317,23:94.772,14:95.203,77:95.436,18:95.995,11:96.906},
 3: {12:88.778,63:89.076,81:89.132,16:89.303,1:89.409,44:89.567,10:89.691,6:89.978,
     5:89.99,41:90.109,3:90.262,31:90.309,27:90.358,30:90.495,43:90.627,55:90.927,
     23:91.088,87:91.09,11:92.206,77:92.33,14:92.646,18:92.92},
 4: {12:87.798,3:87.964,16:88.143,1:88.183,63:88.197,44:88.319,81:88.332,43:88.762,
     10:88.81,27:89.439,30:89.499,87:89.34,55:89.54,31:89.772,23:89.72,41:90.133,
     14:91.098,18:91.164,77:91.629,11:91.967,5:93.737,6:88.789},
 5: {63:72.578,12:72.646,1:72.729,81:72.781,44:72.868,3:72.907,6:72.935,16:72.976,
     41:73.28,43:73.697,27:73.886,30:73.897,5:74.071,10:74.187,55:74.273,87:74.416,
     31:74.845,23:74.851,14:75.196,11:75.429,18:76.195,77:76.272},
 8: {63:66.113,16:66.349,44:66.408,12:66.414,3:66.475,1:66.502,81:66.511,6:66.632,
     30:66.955,41:67.007,10:67.223,5:67.293,87:67.523,27:67.611,31:67.817,43:67.894,
     55:68.252,23:68.509,11:68.945,77:69.03,14:69.942,18:70.363},
}
PTS = {1:25,2:18,3:15,4:12,5:10,6:8,7:6,8:4,9:2,10:1}

def actual_order(race):
    _, fin, dnf, dns, _ = race
    return fin + dnf + dns  # sin clasificar al final, DNS los ultimos

def pos_of(race):
    return {d: i+1 for i, d in enumerate(actual_order(race))}

def finished_pos(race):
    # posicion "real" para features: clasificados su posicion; dnf/dns None
    _, fin, dnf, dns, dnf_cl = race
    out = {d: i+1 for i, d in enumerate(fin)}
    for d in dnf + dns: out[d] = None
    return out

def p2s(p):  # posicion -> 0-100
    if p is None: p = GRID
    return max(0.0, min(100.0, 100.0*(GRID-p)/(GRID-1)))

def features(target_round, driver):
    prior = [r for r in RACES if r[0] < target_round]
    hist = []  # mas reciente primero
    for r in reversed(prior):
        fp = finished_pos(r)
        started = driver not in r[3]
        if driver in fp or driver in r[1] or driver in r[2]:
            hist.append((fp.get(driver), started, driver in r[2] or driver in r[4]))
    # ritmo: 5 recientes peso 5-4-3-2-1
    w = [5,4,3,2,1]; num=den=0.0
    for i,(p,st,_) in enumerate(hist[:5]):
        num += p2s(p)*w[i]; den += w[i]
    ritmo = num/den if den else 50.0
    # clasif: qualis previas
    qpos = [QUALI[q].index(driver)+1 for q in QUALI if q < target_round and driver in QUALI[q]]
    clasif = sum(p2s(p) for p in qpos)/len(qpos) if qpos else 50.0
    # vuelta rapida: gap% medio en qualis previas
    gaps = []
    for q in QBEST:
        if q < target_round and driver in QBEST[q]:
            best = min(QBEST[q].values())
            gaps.append((QBEST[q][driver]-best)/best*100.0)
    vr = max(0.0, min(100.0, 100 - (sum(gaps)/len(gaps))/3.0*100)) if gaps else 30.0
    # consistencia
    scores = [p2s(p) for p,_,_ in hist[:8]]
    if len(scores) >= 2:
        m = sum(scores)/len(scores)
        sd = math.sqrt(sum((s-m)**2 for s in scores)/len(scores))
        cons = max(0.0, min(100.0, 100-sd))
    else: cons = 50.0
    # forma
    if len(scores) >= 4:
        l3 = scores[:3]; p3 = scores[3:6] or scores[3:]
        forma = max(0.0, min(100.0, 50 + sum(l3)/len(l3) - sum(p3)/len(p3)))
    else: forma = 50.0
    # forma equipo
    tp = []
    for r in prior[-3:]:
        fp = finished_pos(r)
        pts = sum(PTS.get(fp.get(d) or 99, 0) for d in TEAMS if TEAMS[d]==TEAMS[driver] and (fp.get(d) is not None))
        tp.append(pts)
    equipo = max(0.0, min(100.0, (sum(tp)/len(tp))/43.0*100)) if tp else 50.0
    # riesgo dnf
    starts = sum(1 for _,st,_ in hist if st)
    dnfs = sum(1 for p,st,dnfev in hist if st and (p is None or dnfev))
    dnf = (dnfs/starts*100.0) if starts else 10.0
    return dict(ritmo=ritmo, clasif=clasif, vr=vr, cons=cons, forma=forma, equipo=equipo, dnf=dnf)

def spearman(rank_pred, rank_real):
    n = len(rank_pred)
    d2 = sum((rank_pred[k]-rank_real[k])**2 for k in rank_pred)
    return 1 - 6*d2/(n*(n**2-1))

def evaluate(weights, targets):
    rhos = []; top10 = []
    for r in RACES:
        if r[0] not in targets: continue
        drivers = actual_order(r)
        f = {d: features(r[0], d) for d in drivers}
        score = {d: (weights.get('ritmo',0)*f[d]['ritmo'] + weights.get('clasif',0)*f[d]['clasif']
                   + weights.get('vr',0)*f[d]['vr'] + weights.get('cons',0)*f[d]['cons']
                   + weights.get('forma',0)*f[d]['forma'] + weights.get('equipo',0)*f[d]['equipo']
                   - weights.get('dnf',0)*f[d]['dnf']) for d in drivers}
        pred_sorted = sorted(drivers, key=lambda d: -score[d])
        pr = {d: i+1 for i,d in enumerate(pred_sorted)}
        rr = pos_of(r)
        rhos.append(spearman(pr, rr))
        real_top10 = set(list(rr)[:0]) # placeholder
        real_top10 = {d for d,p in rr.items() if p<=10}
        pred_top10 = {d for d,p in pr.items() if p<=10}
        top10.append(len(real_top10 & pred_top10)/10.0)
    return sum(rhos)/len(rhos), sum(top10)/len(top10), rhos

TARGETS = [4,5,7,8]
configs = {
 'Solo clasificacion (baseline parrilla)': dict(clasif=1.0),
 'Solo ritmo reciente':                    dict(ritmo=1.0),
 '3 pesos (referencia MotoGP 75/15/10)':   dict(vr=0.75, ritmo=0.15, cons=0.10),
 '3 pesos invertidos (ritmo 60)':          dict(ritmo=0.60, vr=0.25, cons=0.15),
 '4 principales (defaults renorm.)':       dict(ritmo=0.375, clasif=0.281, vr=0.125, cons=0.219),
 '8 completos (defaults sin afinidad)':    dict(ritmo=0.261, clasif=0.196, vr=0.087, cons=0.152,
                                                forma=0.130, equipo=0.109, dnf=0.065),
}
print(f'Objetivos: rondas {TARGETS} (prediciendo solo con datos anteriores)\n')
results = []
for name, wts in configs.items():
    rho, t10, rhos = evaluate(wts, TARGETS)
    results.append((rho, t10, name, rhos))
for rho, t10, name, rhos in sorted(results, reverse=True):
    print(f'{name:42s} Spearman medio={rho:+.3f}  acierto-top10={t10*100:4.0f}%  por GP={["%+.2f"%x for x in rhos]}')

# Busqueda rapida de la mejor mezcla (paso grueso) sobre este muestrario
best = None
step = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6]
for a,b,c,d in product(step, repeat=4):
    s = a+b+c+d
    if abs(s-1.0) > 1e-9 or s == 0: continue
    for e in [0.0, 0.05, 0.1]:
        w = dict(ritmo=a, clasif=b, vr=c, cons=d, dnf=e)
        rho, t10, _ = evaluate(w, TARGETS)
        if best is None or rho > best[0]: best = (rho, t10, dict(w))
print('\nMejor mezcla encontrada (grid grueso, muestra pequena):')
print(f'  {best[2]}  -> Spearman={best[0]:+.3f}, top10={best[1]*100:.0f}%')
