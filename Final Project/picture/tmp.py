s1 = input('input filename: ')
s2 = input ('output filename: ')
fh = open(s1, 'r')
m = [7, 12, 12]
d = {'0':0,'1':1,'2':2,'3':3,'4':4,'5':5,'6':6,'7':7,'8':8\
    ,'9':9,'A':10,'B':11,'C':12,'D':13,'E':14,'F':15}
l = list()
data = fh.readlines()
len = len(data)
for i in range(len):
    if(i < 2):
        l.append(data[i])
        continue
    ss = [d[data[i][0]], d[data[i][1]], d[data[i][2]]]
    flag = True
    cnt = 0
    for j in range(3):
        if abs(m[j]-ss[j]) > 2: flag = False
        cnt += abs(m[j]-ss[j])
        if(cnt > 4): flag = False
    if(flag): l.append('7CC'+(',' if i != len-1 else ';')+'\n')
    else: l.append(data[i])
fh.close()

fh = open(s2, 'w')
fh.writelines(l)