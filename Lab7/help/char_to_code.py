d = {'0':0,'1':1,'2':2,'3':3,'4':4,'5':5,'6':6,'7':7\
    ,'8':8,'9':9,'A':10,'B':11,'C':12,'D':13,'E':14,'F':15}
fh = open('char_to_code.txt', 'w')
while True:
    s = input()
    if s == 'q': break
    key = input()
    n = bin(16*d[s[0]]+d[s[1]])[2:]
    k = 8-len(n)
    n = '0'*k+n
    fh.write(f'9\'b0_{n[0:4]}_{n[4:8]}, // {key} => {s}\n')
fh.close()
    
