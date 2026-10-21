# Segment times, fan-on instants and column names below are the 2026-10-20
# video's (docs/plans/handoff-fase4-1-respiracao.md): edit them per video.
# Per segment and column: 50% crossings (down/up), trough centers, period fit.
import sys
rows=[l.split() for l in open(sys.argv[1])]
hdr=rows[0]; data=[list(map(float,r)) for r in rows[1:]]
segs={'nivel1':(19.9,89.4),'nivel4':(93.9,133.3)}
def smooth(v,k=2):
    return [sum(v[max(0,i-k):i+k+1])/len(v[max(0,i-k):i+k+1]) for i in range(len(v))]
def fit(xs):
    n=len(xs); ks=range(n); mk=sum(ks)/n; mx=sum(xs)/n
    p=sum((k-mk)*(x-mx) for k,x in zip(ks,xs))/sum((k-mk)**2 for k in ks)
    res=[x-(mx+p*(k-mk)) for k,x in zip(ks,xs)]
    return p,max(abs(r) for r in res)
for name,(a,b) in segs.items():
    seg=[r for r in data if a<=r[0]<=b]
    t=[r[0] for r in seg]
    print('==',name)
    for c in ['rearfan','botfans','topfans','ram','edge_bot']:
        v=smooth([r[hdr.index(c)] for r in seg])
        srt=sorted(v); lo=srt[len(v)//50]; hi=srt[-len(v)//50]
        for frac in (0.5,):
            th=lo+frac*(hi-lo)
            dn=[];up=[]
            for i in range(1,len(v)):
                if (v[i-1]-th)*(v[i]-th)<0:
                    tc=t[i-1]+(th-v[i-1])/(v[i]-v[i-1])*(t[i]-t[i-1])
                    (dn if v[i]<v[i-1] else up).append(tc)
            # trough center = midpoint of down crossing and next up crossing
            tr=[]
            for d in dn:
                nu=[u for u in up if u>d]
                if nu: tr.append((d+nu[0])/2)
            pk=[]
            for u in up:
                nd=[d for d in dn if d>u]
                if nd: pk.append((u+nd[0])/2)
            dur_low=[nu-d for d in dn for nu in [min([u for u in up if u>d] or [None])] if nu]
            p,err=fit(tr)
            pp,errp=fit(pk)
            print(f'{c:9s} troughs={[round(x,2) for x in tr]}')
            print(f'          peaks={[round(x,2) for x in pk]}')
            print(f'          period(trough)={p:.3f}s maxres={err:.2f}  period(peak)={pp:.3f}s  low-fraction={sum(dur_low)/len(dur_low)/p:.2f}')
