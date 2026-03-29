function mret = fn_fcol(vect,argfc)
%arg = vect - 0;
%arg = 20*pi*bits2bytes(arg)/255;
%vect = arg;
classe = length(argfc(1,:));
nmx = classe-1;
vt = vect(1:nmx);
vd = vect((nmx+1):2*nmx);
usa = vect((2*nmx)+1:3*nmx);
%
%s = sum(vect);
fc1 = argfc(:,1:nmx);
for i=1:nmx
    a = round(abs(1000*abs(sin(usa(i)))))/1000;
    b = vt(i);
    c = vd(i);
    fc1(:,i) = a*sin(fc1(:,i)*b+c);
    %    fc1(:,i) = a(i)*sin(fc1(:,i)*vt(i)+vd(i));
end
ones_ = ones(nmx,1);
mret = abs(fc1*ones_);
end
