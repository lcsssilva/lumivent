# Usage: python3 -I plot.py series.txt out.ppm [t0 t1 [col,col]]; then
# ffmpeg -i out.ppm out.png
# Plot columns of a whitespace table into a PPM: one row panel per column.
import sys
fn,out=sys.argv[1],sys.argv[2]
t0=float(sys.argv[3]) if len(sys.argv)>3 else None
t1=float(sys.argv[4]) if len(sys.argv)>4 else None
cols=sys.argv[5].split(',') if len(sys.argv)>5 else None
lines=open(fn).read().split('\n')
hdr=lines[0].split()
rows=[list(map(float,l.split())) for l in lines[1:] if l.strip()]
if t0 is not None: rows=[r for r in rows if t0<=r[0]<=t1]
names=[h for h in hdr[1:] if cols is None or h in cols]
idx=[hdr.index(n) for n in names]
W,PH=1800,150
H=PH*len(idx)
img=bytearray(b'\xff'*W*H*3)
def px(x,y,c):
    if 0<=x<W and 0<=y<H:
        p=(y*W+x)*3; img[p:p+3]=bytes(c)
ta,tb=rows[0][0],rows[-1][0]
# grid every second (light), every 5 s (darker)
import math
for s in range(math.ceil(ta),int(tb)+1):
    x=int((s-ta)/(tb-ta)*(W-1))
    c=(150,150,150) if s%5==0 else (225,225,225)
    for y in range(H): px(x,y,c)
for k,ci in enumerate(idx):
    vs=[r[ci] for r in rows]
    lo,hi=min(vs),max(vs)
    if hi==lo: hi=lo+1
    for y in range(PH): px(0,k*PH+y,(0,0,0))
    for x in range(W): px(x,k*PH,(0,0,0))
    prev=None
    for r in rows:
        x=int((r[0]-ta)/(tb-ta)*(W-1))
        y=k*PH+PH-4-int((r[ci]-lo)/(hi-lo)*(PH-8))
        if prev:
            y0,y1=sorted((prev[1],y))
            for yy in range(y0,y1+1): px(x,yy,(200,0,0))
        px(x,y,(200,0,0)); prev=(x,y)
with open(out,'wb') as f:
    f.write(b'P6 %d %d 255\n'%(W,H)); f.write(img)
print(names, ta, tb)
