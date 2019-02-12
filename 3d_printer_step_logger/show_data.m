% Load the cutecom log

[x,y,z,e] = textread("/home/aleph/cutecom.log", "%4s%4s%5s%5s\n");
x = hex2dec(x);
y = hex2dec(y);
z = hex2dec(z);
e = hex2dec(e);

plot3(x,y,z);
hold on;
scatter3(x,y,z,'r');