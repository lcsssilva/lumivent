# Usage: python3 -I acf.py series.txt t0 t1 [col,col]: autocorrelation peaks
# (lag in s, height) per column, for periodic patterns without a clean trough
# (scans, waves).
# Autocorrelation peaks per column over [t0, t1] (uniform 30 Hz resample).
import sys
fn,t0,t1=sys.argv[1],float(sys.argv[2]),float(sys.argv[3])
rows=[l.split() for l in open(fn)]; hdr=rows[0]
data=[list(map(float,r)) for r in rows[1:] if t0<=float(r[0])<=t1]
fs=30.0
def resample(ci):
    out=[];j=0;t=t0
    while t<=data[-1][0]:
        while j+1<len(data) and data[j+1][0]<t: j+=1
        if j+1<len(data):
            a,b=data[j],data[j+1]; f=(t-a[0])/(b[0]-a[0]) if b[0]>a[0] else 0
            out.append(a[ci]+f*(b[ci]-a[ci]))
        t+=1/fs
    return out
for c in hdr[1:] if len(sys.argv)<5 else sys.argv[4].split(','):
    v=resample(hdr.index(c)); m=sum(v)/len(v); v=[x-m for x in v]; n=len(v)
    var=sum(x*x for x in v)/n
    ac=[sum(v[i]*v[i+L] for i in range(n-L))/(n-L)/var for L in range(int(8*fs))]
    peaks=[(L/fs,round(ac[L],2)) for L in range(int(0.3*fs),len(ac)-1) if ac[L]>ac[L-1] and ac[L]>=ac[L+1] and ac[L]>0.2]
    ref=[]
    for L,_ in [(int(p*fs+0.5),q) for p,q in peaks]:
        y0,y1,y2=ac[L-1],ac[L],ac[L+1]; d=0.5*(y0-y2)/(y0-2*y1+y2) if (y0-2*y1+y2)!=0 else 0
        ref.append(f'{(L+d)/fs:.3f}({ac[L]:.2f})')
    print(f'{c:8s}', ' '.join(ref[:8]))
