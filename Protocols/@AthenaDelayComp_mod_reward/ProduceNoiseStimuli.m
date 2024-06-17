clear all

T=1000;
fcut=110;
Fs=10000;
filter_type='GAUS';
outband=55;
Ind=[0.4];

minS1_d=1;
maxS1_d=30;
numClass=8;
 
S1_d(1)=minS1_d;
S2_d(1)=S1_d(1)*(1-Ind)/(1+Ind);
S1_u(1)=S1_d;
S2_u(1)=S1_u(1)*(1+Ind)/(1-(Ind));
for ii=2:numClass
S1_d(ii)=S2_u(ii-1);    
S2_d(ii)=S1_d(ii)*(1-Ind)/(1+Ind);
S1_u(ii)=S1_d(ii);    
S2_u(ii)=S1_u(ii)*(1+Ind)/(1-Ind);
end

[rawA rawB filtA filtB]=noise(Sigma1(ss),Sigma2(ss),T,fcut,Fs,filter_type,outband);


pairs=[];
pairs(:,1)=[S1_d S1_u];
pairs(:,2)=[S2_d S2_u];
thesepairs=pairs(2:end-1,:)
LOGplotPairs(thesepairs(:,1),thesepairs(:,2),'s',18,'k',1,16)

