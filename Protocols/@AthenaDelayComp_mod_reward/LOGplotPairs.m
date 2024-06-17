function LOGplotPairs(x,y,marker,markersize,markeredgecolor,thislinewidth,FONTSIZE)


% delete(gca)
% load('NEWHOT','HOTETOBOKHORAM') 

%  position =     [16         124        1019         761];
% % 
%   figure('Position',position);

% if nargin <8
% LogOrLin='linear';
% end
    
if nargin <4
    marker='.';
end


% Plot the points
hold on
x=log(x);
y=log(y);
for i=1:length(x)

% loglog(x(i),y(i),marker,'color',map(in,:),'markerfacecolor',map(in,:),'MarkerSize',markersize)   
% plot3(x(i),y(i),v(i),marker,'MarkerSize',markersize,'MarkerEdgeColor',markeredgecolor,'LineWidth',thislinewidth)
    plot(x(i),y(i),marker,'MarkerSize',markersize,'MarkerEdgeColor',markeredgecolor,'LineWidth',thislinewidth)

end

xlim([min([x ;y])-min([x ;y])/2 max([x ;y])+min([x ;y])/2])
ylim([min([x; y])-min([x ;y])/2 max([x; y])+-min([x ;y])/2])
hold off

% figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2])

Ylabel('log_e \sigma_2','FontSize',FONTSIZE,'FontName','Cambria Math');  
set(gca,'Fontsize',15)
Xlabel('log_e \sigma_1','FontSize',FONTSIZE,'FontName','Cambria Math')

% grid on
setyticklabels=1

if setyticklabels==1

Ytick=get(gca,'YtickLabel');
Xtick=get(gca,'XtickLabel');
% 
% Ytick=num2str((3:0.5:6)');
% Xtick=num2str((3:0.5:6)');

%     set(gca,'ytick',[],'xtick',[]);
end
% 
% axis square
% HUMANORRAT=2
% if HUMANORRAT==2
% ylim([2.5 6])
% xlim([2.2 6.3])
% else
%  ylim([3.5 6])
%  xlim([3.5 6.5])
% end
if setyticklabels==1
set(gca,'ytick',str2num(Ytick),'xtick',str2num(Xtick));
set(gca,'yticklabel',num2str(round(round(exp(str2num(Ytick)).*100)./100)),'xticklabel',num2str(round(round(exp(str2num(Xtick)).*100)./100)));
end

%  set(gca,'yticklabel',num2str(round(exp(str2num(Ytick)).*100)./100),'xticklabel',num2str(round(exp(str2num(Xtick)).*100)./100));
view(2)
