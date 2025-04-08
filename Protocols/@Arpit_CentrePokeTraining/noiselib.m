function [base,filtbase]=noiselib(num,T,fcut,Fs,filter_type,outband)
close all
clc

%%%%%%%%%%%%%%%%% Determines of the type of filter used %%%%%%%%%%%%%%%%%%%
%'LPFIR': lowpass FIR%%%%%'FIRLS': Least square linear-phase FIR filter design
%'BUTTER': IIR Butterworth lowpass filter%%%%%%'GAUS': Gaussian filter (window)
%'MOVAVRG': Moving average FIR filter%%%%%%%%'KAISER': Kaiser-window FIR filtering
% 'EQUIRIP':Eqiripple FIR filter%%%%% 'HAMMING': Hamming-window based FIR 
% T is duration of each signal in milisecond, fcut is the cut-off frequency                                     
% Fs is the sampling frequency
% outband=40;

for ii=1:num
s = RandStream('mcg16807','Seed',ii)
RandStream.setDefaultStream(s)

replace=1;
L=T*Fs/1000;                      % Length of signal
t=L*1000*linspace(0,1,L)/Fs;          % time in miliseconds
%%%%%%%%%%% produce position values %%%%%%%
pos1 = randn(Fs,1);
pos1(pos1>outband)=[];
pos1(pos1<-outband)=[];
    
base(:,num)=pos1;
%base = randsample(pos1,L,replace);
%%%% Filter the original position values %%%%%%
filtbase(:,num)=filt(base,fcut,Fs,filter_type);

end

end

%%%%%% plot the row and filtered position values %%%%%%%%%
% subplot(2,2,1)
% plot(t,base,'r');
% ylabel('base')
% xlabel('Time (ms)')
% subplot(2,2,2)
% plot(t,target,'g');
% ylabel('target')
% xlabel('Time (ms)')
% subplot(2,2,3)
% plot(t,filtbase)
% ylabel('filtbase')
% xlabel('Time (ms)')
% subplot(2,2,4)
% plot(t,filttarget)
% ylabel('filttarget')
% xlabel('Time (ms)')
