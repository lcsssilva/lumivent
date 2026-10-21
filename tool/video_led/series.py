# Redness per frame of rectangular regions of a raw rgb24 dump.
#
#   ffmpeg -i v.mp4 -vf "scale=120:213,format=rgb24" -fps_mode passthrough \
#     -f rawvideo frames.rgb
#   ffprobe -v error -select_streams v -show_entries \
#     frame=best_effort_timestamp_time -of csv=p=0 v.mp4 > pts.txt
#   python3 -I series.py frames.rgb pts.txt series.txt 120x213 \
#     rearfan=2,62,36,110 ram=72,78,94,130
#
# Value = mean of max(0, R - max(G, B)) over the region (red effects only).
import sys
fn,ptsfn,out,size=sys.argv[1:5]
W,H=map(int,size.split('x'))
regions={}
for a in sys.argv[5:]:
    k,v=a.split('=')
    regions[k]=tuple(map(int,v.split(',')))
pts=[float(l) for l in open(ptsfn)]
fs=W*H*3
with open(fn,'rb') as f, open(out,'w') as o:
    o.write('t '+' '.join(regions)+'\n')
    i=0
    while True:
        b=f.read(fs)
        if len(b)<fs: break
        vals=[]
        for (x0,y0,x1,y1) in regions.values():
            s=0
            for y in range(y0,y1):
                row=y*W*3
                for x in range(x0,x1):
                    p=row+x*3
                    r,g,bb=b[p],b[p+1],b[p+2]
                    d=r-(g if g>bb else bb)
                    if d>0: s+=d
            vals.append(s/((x1-x0)*(y1-y0)))
        o.write(f'{pts[i]:.4f} '+' '.join(f'{v:.2f}' for v in vals)+'\n')
        i+=1
