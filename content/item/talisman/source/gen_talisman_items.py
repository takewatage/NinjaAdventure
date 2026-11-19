from PIL import Image
OL=(20,27,27,255)
PAPER=(242,234,241,255); PSH=(210,196,190,255)
DPAPER=(52,44,66,255); DPSH=(36,30,48,255)
E={ # id: name, dark, main, light, glyph
 'fire':('火',(122,22,26),(201,40,31),(255,173,93),[
  "...c...",
  "..cac..",
  ".cacac.",
  ".cabac.",
  "cabbbac",
  "cabbbac",
  ".ccccc."]),
 'water':('水',(18,63,115),(27,111,179),(111,211,245),[
  "...c...",
  "..cac..",
  ".cbaac.",
  "cbaaaac",
  "caaaaac",
  ".caaac.",
  "..ccc.."]),
 'wind':('風',(34,96,44),(108,184,58),(190,230,120),[
  ".cccc..",
  "c....c.",
  "c.cc.c.",
  "c.c..c.",
  "c..cc..",
  ".c.....",
  "..ccccc"]),
 'thunder':('雷',(150,98,10),(240,190,40),(255,214,60),[
  "...cbb.",
  "..cbb..",
  ".cbb...",
  "cbbbbbc",
  "...bbc.",
  "..bbc..",
  ".bc...."]),
 'earth':('土',(78,48,26),(150,96,52),(206,156,96),[
  ".......",
  "...c...",
  "..cbc..",
  ".cbaac.",
  "cbaaaac",
  "caaaaac",
  "ccccccc"]),
 'yang':('陽',(176,96,20),(240,150,40),(255,224,120),[
  ".c.c.c.",
  "..aaa..",
  "cabbbac",
  ".abbba.",
  "cabbbac",
  "..aaa..",
  ".c.c.c."]),
 'yin':('陰',(70,30,110),(150,90,210),(210,170,255),[
  "..bbb..",
  ".bac...",
  "bac....",
  "ba.....",
  "bac....",
  ".bac...",
  "..bbb.."]),
}
ORDER=['fire','water','wind','thunder','earth','yang','yin']
def draw(k):
  name,dk,mn,lt,g=E[k]
  dark = k=='yin'
  P,S = (DPAPER,DPSH) if dark else (PAPER,PSH)
  im=Image.new('RGBA',(16,16),(0,0,0,0)); px=im.load()
  x0,x1,y0,y1=2,12,1,14
  for y in range(y0,y1+1):
    for x in range(x0,x1+1):
      if x in(x0,x1) or y in(y0,y1): px[x,y]=OL
      else: px[x,y]=S if (x==x1-1 or y==y1-1) else P
  # colored band top and bottom
  for x in range(x0+1,x1):
    px[x,y0+1]=mn+(255,); px[x,y1-1]=dk+(255,)
  col={'c':dk,'a':mn,'b':lt}
  for j,row in enumerate(g):
    for i,ch in enumerate(row):
      if ch in col: px[4+i,4+j]=col[ch]+(255,)
  return im
sheet=Image.new('RGBA',(16*len(ORDER),16),(0,0,0,0))
for i,k in enumerate(ORDER): sheet.paste(draw(k),(16*i,0))
sheet.save('talisman_items.png')
big=Image.new('RGBA',(sheet.width*10+20,180),(70,110,70,255))
big.paste(sheet.resize((sheet.width*10,160),Image.NEAREST),(10,10),sheet.resize((sheet.width*10,160),Image.NEAREST))
big.save('preview_big.png')

# --- 術符エディタ（artifact）の保存データから作り直す ---
# 使い方: python3 gen_talisman_items.py edit.json out.png
#   edit.json は エディタの db「talisman/current」の中身（format: talisman_items/v1）
def hexc(h): h=h.lstrip('#'); return tuple(int(h[i:i+2],16) for i in (0,2,4))+(255,)
def build_from_edit(d):
  pl,ps=[hexc(c) for c in d['paper']['light']]; dl,ds=[hexc(c) for c in d['paper']['dark']]
  ol=hexc(d['outline']); gx,gy=d['glyph_origin']; els=d['elements']
  out=Image.new('RGBA',(16*len(els),16),(0,0,0,0)); px=out.load()
  for i,e in enumerate(els):
    P,S=(dl,ds) if e['paper']=='dark' else (pl,ps); ox=16*i
    dk,mn,lt=hexc(e['dark']),hexc(e['main']),hexc(e['light'])
    for y in range(1,15):
      for x in range(2,13):
        if x in(2,12) or y in(1,14): c=ol
        elif y==2: c=mn
        elif y==13: c=dk
        else: c=S if (x==11 or y==12) else P
        px[ox+x,y]=c
    for j,row in enumerate(e['glyph']):
      for k,ch in enumerate(row):
        c={'c':dk,'a':mn,'b':lt}.get(ch)
        if c: px[ox+gx+k,gy+j]=c
  return out
if __name__=='__main__':
  import sys,json
  if len(sys.argv)>=3: build_from_edit(json.load(open(sys.argv[1]))).save(sys.argv[2])
