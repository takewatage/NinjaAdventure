from PIL import Image
import json
meta=json.load(open('meta.json'))
names=['normal','silver','gold','rare','ancient','karakuri']; S=5; BG=(61,107,61,255)
sheets={n:Image.open(f'chest_{n}.png') for n in names}
# strip image: all frames per chest row
maxf=max(len(meta[n]) for n in names)
strip=Image.new('RGBA',(32*maxf*S,32*len(names)*S),BG)
for r,n in enumerate(names):
    for i in range(len(meta[n])):
        f=sheets[n].crop((0,32*i,32,32*i+32)).resize((32*S,32*S),Image.NEAREST)
        strip.paste(f,(32*S*i,32*S*r),f)
strip.save('preview_frames.png')
# gif: all 4 side by side, each plays its sequence then holds open 30 ticks then closed 15
tl={}
for n in names:
    l=[]
    for i,(lab,t) in enumerate(meta[n]):
        if i==0: t=20
        if i==len(meta[n])-1: t=40
        l+= [i]*t
    tl[n]=l
L=max(len(v) for v in tl.values())
frames=[]
for k in range(0,L,1):
    im=Image.new('RGBA',(32*len(names)*S,32*S),BG)
    for c,n in enumerate(names):
        i=tl[n][min(k,len(tl[n])-1)]
        f=sheets[n].crop((0,32*i,32,32*i+32)).resize((32*S,32*S),Image.NEAREST)
        im.paste(f,(32*S*c,0),f)
    frames.append(im.convert('RGB'))
frames[0].save('preview.gif',save_all=True,append_images=frames[1:],duration=33,loop=0)
print(L)
