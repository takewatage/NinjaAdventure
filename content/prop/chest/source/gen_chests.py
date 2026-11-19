from PIL import Image
OL=(20,27,27)
INT=(36,22,28); INT2=(62,38,42)
def rgb(*c): return c
class Cv:
    def __init__(s): s.im=Image.new('RGBA',(32,32),(0,0,0,0)); s.p=s.im.load()
    def px(s,x,y,c):
        if 0<=x<32 and 0<=y<32 and c is not None: s.p[x,y]=c+(255,) if len(c)==3 else c
    def hl(s,x0,x1,y,c):
        for x in range(x0,x1+1): s.px(x,y,c)
    def rect(s,x0,y0,x1,y1,c):
        for y in range(y0,y1+1): s.hl(x0,x1,y,c)

SPECS={
 'normal':dict(W=14,Bf=6,Lf=3,Lt=3,
   wood=[(92,52,38),(150,90,52),(196,132,78),(226,176,112)], inner=(110,64,44),
   band=[(79,90,112),(127,144,166),(180,194,211)], bands=[3,-4], lock='gold'),
 'silver':dict(W=14,Bf=6,Lf=3,Lt=3,
   wood=[(84,96,118),(150,164,184),(198,210,224),(236,242,250)], inner=(70,80,100),
   band=[(60,70,90),(104,118,140),(150,164,184)], bands=[3,-4], lock='gold'),
 'gold':dict(W=14,Bf=6,Lf=3,Lt=3,
   wood=[(150,90,20),(222,164,40),(248,206,80),(255,240,160)], inner=(140,84,24),
   band=[(150,90,20),(190,124,30),(232,170,50)], bands=[3,-4], lock='gold', lockpal=[(84,96,118),(180,194,211),(236,242,250)], gem=(201,40,31)),
 'rare':dict(W=16,Bf=7,Lf=4,Lt=3,
   wood=[(110,20,28),(170,34,38),(214,64,54),(238,110,84)], inner=(96,24,30),
   band=[(170,104,24),(232,180,40),(255,232,140)], bands=[1,-2], lock='gold_big', corners=True, trim=True, gem=(90,168,255)),
 'ancient':dict(W=18,Bf=7,Lf=4,Lt=4,
   wood=[(34,62,64),(58,104,98),(90,146,128),(144,188,160)], inner=(40,70,68),
   band=[(84,72,52),(132,112,74),(178,156,104)], bands=[2,-3], lock='gold', lockpal=[(84,72,52),(132,112,74),(178,156,104)], moss=True, rune=True),
 'karakuri':dict(W=22,Bf=9,Lf=5,Lt=4,
   wood=[(52,34,36),(88,58,50),(124,86,64),(160,118,84)], inner=(70,46,42),
   band=[(150,104,36),(214,166,64),(250,218,128)], bands=[2,-3], lock='karakuri', corners=True, lattice=True),
}
GOLD=[(170,104,24),(232,180,40),(255,232,140)]
PAPER=(242,234,241); PAPER2=(210,196,190); SEALRED=(201,40,31)
MOSS=[(70,120,40),(108,184,58)]

def chest(name, lid='closed', gap=0, Lo=None, squash=0, seal_state=0, gear=0, latch=0):
    S=SPECS[name]; c=Cv(); W=S['W']; x0=16-W//2; x1=x0+W-1; yB=28
    w=S['wood']; band=S['band']
    Bf=S['Bf']-squash; Lf=S['Lf']; Lt=S['Lt']
    ys=yB-Bf  # seam row (top outline of body)
    bxs=[x0+b if b>=0 else x1+b+1 for b in S['bands']]
    bxs=bxs+[x0+W-1-(b-x0) for b in bxs]
    bxs=sorted(set(bxs))
    # ---- body front ----
    c.rect(x0,ys,x1,yB,OL)
    for y in range(ys+1,yB):
        for x in range(x0+1,x1):
            col=w[1]
            if y==yB-1: col=w[0]
            elif x==x1-1: col=w[0]
            elif y==ys+1: col=w[2]
            c.px(x,y,col)
    for bx in bxs:
        for y in range(ys+1,yB):
            c.px(bx,y,band[0] if y==yB-1 else band[1])
    if S.get('trim'):
        c.hl(x0+1,x1-1,yB-1,GOLD[0]); c.hl(x0+1,x1-1,ys+1,GOLD[1])
    if S.get('corners'):
        for (cx,cy) in [(x0+1,yB-1),(x1-1,yB-1)]:
            c.px(cx,cy,GOLD[1])
    if S.get('rune'):
        mid=16; ry=ys+3
        for dx in (-5,-4,4,5): c.px(mid+dx-1,ry,w[0])
        c.px(mid-6,ry+1,w[0]); c.px(mid+5,ry+1,w[0])
    if S.get('moss'):
        for (mx,my) in [(x0+1,yB-1),(x0+2,yB-1),(x0+1,yB-2),(x1-2,yB-1),(x1-1,yB-2)]:
            c.px(mx,my,MOSS[1] if (mx+my)%2 else MOSS[0])
    # karakuri gear on body front
    if S['lock']=='karakuri':
        draw_gear(c,16,ys+5,gear,band)
        # side latches pins
        for side,xx in ((-1,x0),(1,x1)):
            for k in range(2):
                c.px(xx+side*(k+latch),ys,band[1]); c.px(xx+side*(k+latch),ys+1,band[0])
            c.px(xx+side*(2+latch),ys,OL); c.px(xx+side*(2+latch),ys+1,OL)
    if lid=='closed':
        # gap (lid lifted)
        top_lid_bottom=ys-gap
        for g in range(gap):
            y=ys-1-g
            c.px(x0,y,OL); c.px(x1,y,OL); c.hl(x0+1,x1-1,y,INT)
        lb=top_lid_bottom  # lid bottom outline row
        if gap>0: c.hl(x0,x1,lb,OL)
        yf_top=lb-Lf     # lid-front top row index (edge row)
        ytop=yf_top-Lt   # top outline row
        c.rect(x0,ytop,x1,lb-1,OL)
        for y in range(ytop+1,lb):
            for x in range(x0+1,x1):
                if y>yf_top: col=w[1] if x!=x1-1 else w[0]
                elif y==yf_top: col=w[3]
                else: col=w[2] if x!=x1-1 else w[1]
                c.px(x,y,col)
        # front-top edge outline across? keep highlight
        c.px(x0,ytop,None); 
        c.p[x0,ytop]=(0,0,0,0); c.p[x1,ytop]=(0,0,0,0)
        for bx in bxs:
            for y in range(ytop+1,lb):
                c.px(bx,y,band[2] if y<=yf_top else band[1])
        if S.get('trim'):
            c.hl(x0+1,x1-1,yf_top,GOLD[2]); c.hl(x0+1,x1-1,lb-1,GOLD[0])
        if S.get('lattice'):
            for y in range(ytop+1,yf_top):
                for x in range(x0+1,x1):
                    if (x-x0)%3==0 or (y-ytop)%2==0: c.px(x,y,w[1])
            c.hl(x0+1,x1-1,yf_top,band[2])
        if S.get('corners'):
            c.px(x0+1,ytop+1,GOLD[2]); c.px(x1-1,ytop+1,GOLD[2])
        if S.get('moss'):
            for (mx,my) in [(x0+2,ytop+1),(x0+3,ytop+1),(x0+1,ytop+2),(x1-3,ytop+1)]:
                c.px(mx,my,MOSS[1] if (mx+my)%2 else MOSS[0])
        draw_lock(c,S,lb,gap)
        if S.get('seal'): draw_seal(c,lb,ys,ytop,seal_state)
        if S['lock']=='karakuri':
            # hasp bar on seam, retracts into lid when latch>0
            hy=lb-1-latch*2  # hasp rises into the lid when unlocked
            c.rect(14,hy-1,17,hy+2,OL); c.rect(15,hy,16,hy+1,band[1]); c.px(15,hy,band[2])
    else:
        # open: interior then lid inner face
        Ih=Lt
        yback=ys-Ih-1
        c.rect(x0,yback,x1,ys,OL)
        for y in range(yback+1,ys):
            c.hl(x0+1,x1-1,y,INT2 if y==yback+1 else INT)
        # front rim highlight
        c.hl(x0+1,x1-1,ys,OL)
        ylt=yback-Lo
        c.rect(x0,ylt,x1,yback,OL)
        for y in range(ylt+1,yback):
            for x in range(x0+1,x1):
                c.px(x,y,S['inner'] if x!=x1-1 else w[0])
        c.hl(x0+1,x1-1,yback-1,w[0])
        c.p[x0,ylt]=(0,0,0,0); c.p[x1,ylt]=(0,0,0,0)
        for bx in bxs:
            for y in range(ylt+1,yback):
                c.px(bx,y,band[0])
        # lock tip at top edge of lid
        if S['lock'] in ('gold','gold_big'):
            G=S.get('lockpal',GOLD); c.px(15,ylt,G[1]); c.px(16,ylt,G[1]); c.px(15,ylt-1,OL); c.px(16,ylt-1,OL)
            c.px(14,ylt,OL); c.px(17,ylt,OL)
        if S['lock']=='karakuri':
            c.px(15,ylt+1,band[1]); c.px(16,ylt+1,band[1])
        if S.get('seal') and seal_state in (3,4):
            pass
    if S.get('seal') and lid!='closed':
        draw_seal_bits(c,seal_state,ys)
    return c.im

def draw_lock(c,S,lb,gap):
    if S['lock']=='gold':
        x0,x1,y0,y1=14,17,lb-2,lb+1
    elif S['lock']=='gold_big':
        x0,x1,y0,y1=13,18,lb-2,lb+2
    else: return
    G=S.get('lockpal',GOLD)
    c.rect(x0,y0,x1,y1,OL)
    for y in range(y0+1,y1):
        for x in range(x0+1,x1):
            c.px(x,y,G[2] if y==y0+1 else G[1])
    c.px(15,y1-1,OL); c.px(16,y1-1,OL) if S['lock']=='gold_big' else None
    if S['lock']=='gold': c.px(15,y1-1,OL)
    if S.get('gem'):
        if S['lock']=='gold_big': c.px(15,y0+1,S['gem']); c.px(16,y0+1,S['gem'])
        else: c.px(15,y0+1,S['gem'])
    if gap>0:
        # lower half of plate stays attached to lid -> nothing to do
        pass

def draw_seal(c,lb,ys,ytop,st):
    # vertical paper strip x 15..17 from lid top+1 to ys+4
    ya,yb=ytop+1,ys+4
    if st==0:
        for y in range(ya,yb+1):
            for x in (15,16,17):
                c.px(x,y,PAPER if x<17 else PAPER2)
        c.px(16,lb-3,SEALRED); c.px(16,lb-2,SEALRED); c.px(15,lb-2,SEALRED); c.px(17,lb-2,SEALRED); c.px(16,ys+2,SEALRED)
        for y in (ya,yb): pass
    elif st==1:  # torn: upper part on lid, lower stays on body, jagged
        for y in range(ya,lb):
            for x in (15,16,17): c.px(x,y,PAPER if x<17 else PAPER2)
        c.px(16,lb-3,SEALRED)
        c.px(15,lb,PAPER); c.px(17,lb-1,None)
        for y in range(ys+1,yb+1):
            for x in (15,16,17): c.px(x,y,PAPER if x<17 else PAPER2)
        c.px(16,ys+1,None); c.p[16,ys+1]=c.p[16,ys+1]
        c.px(16,ys+2,SEALRED)

def draw_seal_bits(c,st,ys):
    bits={2:[(9,ys-12),(21,ys-10),(12,ys-6)],3:[(7,ys-15),(23,ys-13)],4:[]}.get(st,[])
    for (x,y) in bits:
        c.px(x,y,PAPER); c.px(x+1,y,PAPER2); c.px(x,y+1,PAPER2)

def draw_gear(c,cx,cy,phase,band):
    # 7x7 gear; teeth alternate orthogonal / diagonal by phase
    r=[(dx,dy) for dx in range(-2,3) for dy in range(-2,3) if dx*dx+dy*dy<=5]
    for dx,dy in r: c.px(cx+dx,cy+dy,band[1])
    for dx,dy in [(-1,-1),(0,-2),(1,-1)]: c.px(cx+dx,cy+dy,band[2])
    if phase%2==0: teeth=[(0,-3),(0,3),(-3,0),(3,0)]
    else: teeth=[(-2,-2),(2,-2),(-2,2),(2,2)]
    # outline ring
    ring=[(dx,dy) for dx in range(-3,4) for dy in range(-3,4) if 5<dx*dx+dy*dy<=10]
    for dx,dy in ring: c.px(cx+dx,cy+dy,OL)
    for dx,dy in teeth: c.px(cx+dx,cy+dy,band[1])
    c.px(cx,cy,OL); c.px(cx+(1 if phase%2 else 0),cy+(0 if phase%2 else 1),band[0])

# ---------- animation definitions: (kwargs, ticks@30fps, label) ----------
def frames_for(name):
    S=SPECS[name]; Lf,Lt=S['Lf'],S['Lt']
    seal=S.get('seal',False)
    seq=[]
    seq.append((dict(),1,'closed'))
    if name=='karakuri':
        seq+= [(dict(gear=1),3,'gear1'),(dict(gear=2),3,'gear2'),(dict(gear=3,latch=1),3,'gear3_unlatch'),(dict(gear=4,latch=1),3,'gear4')]
        base=dict(gear=4,latch=1)
    else: base={}
    seq+=[
      (dict(base,squash=1,seal_state=0),3,'squash'),
      (dict(base,gap=2,seal_state=1 if seal else 0),2,'lift'),
      (dict(base,lid='open',Lo=Lf+Lt,seal_state=2),2,'lid_up'),
      (dict(base,lid='open',Lo=Lf,seal_state=3),2,'lid_back'),
      (dict(base,lid='open',Lo=Lf+1,seal_state=4),1,'opened'),
    ]
    return seq

if __name__=='__main__':
    import json
    meta={}
    for n in SPECS:
        seq=frames_for(n)
        sheet=Image.new('RGBA',(32,32*len(seq)),(0,0,0,0))
        for i,(kw,t,lab) in enumerate(seq):
            sheet.paste(chest(n,**kw),(0,32*i))
        sheet.save(f'chest_{n}.png')
        meta[n]=[(lab,t) for kw,t,lab in seq]
    json.dump(meta,open('meta.json','w'),ensure_ascii=False,indent=1)
