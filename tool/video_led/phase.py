# Segment times, fan-on instants and column names below are the 2026-10-20
# video's (docs/plans/handoff-fase4-1-respiracao.md): edit them per video.
import sys
rows=[l.split() for l in open(sys.argv[1])]
hdr=rows[0]; data=[list(map(float,r)) for r in rows[1:]]
segs={'L1':(19.9,89.4,19.81),'L4':(93.7,133.3,93.61)}
def smooth(v,k=2): return [sum(v[max(0,i-k):i+k+1])/len(v[max(0,i-k):i+k+1]) for i in range(len(v))]
def events(t,v):
    srt=sorted(v); lo=srt[len(v)//50]; hi=srt[-len(v)//50]; th=(lo+hi)/2
    dn=[];up=[]
    for i in range(1,len(v)):
        if (v[i-1]-th)*(v[i]-th)<0:
            tc=t[i-1]+(th-v[i-1])/(v[i]-v[i-1])*(t[i]-t[i-1])
            (dn if v[i]<v[i-1] else up).append(tc)
    tr=[(d+min(u for u in up if u>d))/2 for d in dn if any(u>d for u in up)]
    pk=[(u+min(d for d in dn if d>u))/2 for u in up if any(d>u for d in dn)]
    return tr,pk
def fit(xs,t0):
    # x_k = a + T*k with k counted from the first event; return a, T
    n=len(xs); ks=list(range(n)); mk=sum(ks)/n; mx=sum(xs)/n
    T=sum((k-mk)*(x-mx) for k,x in zip(ks,xs))/sum((k-mk)**2 for k in ks)
    return mx-T*mk,T
for name,(a,b,on) in segs.items():
    seg=[r for r in data if a<=r[0]<=b]; t=[r[0] for r in seg]
    res={}
    for c in ['rearfan','botfans','topfans','ram']:
        v=smooth([r[hdr.index(c)] for r in seg])
        tr,pk=events(t,v)
        a0,T=fit(tr,on); p0,Tp=fit(pk,on)
        res[c]=(a0,T,p0,Tp)
    ram=res['ram']; T_r=(ram[1]+ram[3])/2
    # canvas t0: the RAM is dark at t0 + k*T_r and bright at t0 + (k+1/2)*T_r
    c1=ram[0]; c2=ram[2]-T_r/2
    while c1-T_r>on-1: c1-=T_r
    while c2-T_r>on-1: c2-=T_r
    t0=(c1+c2)/2
    Tf=sum(res[c][1]+res[c][3] for c in ['rearfan','botfans','topfans'])/6
    ftr=sum(res[c][0] for c in ['rearfan','botfans','topfans'])/3
    fpk=sum(res[c][2] for c in ['rearfan','botfans','topfans'])/3
    print(f'{name}: fans on {on:.2f}  canvas t0 {t0:.3f} (trough {c1:.3f} / peak {c2:.3f})  T_ram {T_r:.4f}')
    print(f'   fans T {Tf:.4f}  first trough {ftr:.3f} -> +{ftr-t0:.3f} s from t0 = {(ftr-t0)/Tf:.4f} T; first peak {fpk:.3f}; trough-peak {(fpk-ftr):.3f} (T/2={Tf/2:.3f})')
