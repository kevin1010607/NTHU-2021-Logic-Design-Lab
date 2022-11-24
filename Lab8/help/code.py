fh = open('code.txt', 'w')
info = list()
LR = input('L or R? ')
while True:
    s = input().split()
    if(len(s) == 1): break
    num = int(s[0])
    tone = '`'+s[1]
    info.append([num, tone])

idx = 0
prev = ''
p = ['\talways @* begin\n', '\t\tcase(beat)\n']
for i in info:
    if i[1] == prev and i[1] != '`sil':
        p[-1] = p[-1][:-6]+'`sil;\n'
    prev = i[1]
    for j in range(i[0]//2):
        if idx%64 == 0: p.append(f'\t\t\t// --- Measure {idx//64+1} ---\n')
        s = f'\t\t\t9\'d{idx}: freq{LR} = {i[1]};\t\t9\'d{idx+1}: freq{LR} = {i[1]};\n'
        p.append(s)
        idx += 2

p.append('\t\tendcase\n')
p.append('\tend\n')

fh.writelines(p)
fh.close()
