function [] = test_if_ready(ratname,from, varargin)

if nargin < 3
    to = '999999';
end;

% % Get psych curves for range
% psych_singleday_multi(ratname, from, to);
% figure__tile(300,300,'left2right');
% set(double(gca),'FontSize', 12);

% Show numerical trend through time
psychnums_over_time(ratname, 'from', from,'to',to);
set(double(gcf),'Position',[5 270 700 215]);
sub__shrinktitle(double(gcf),12);
set(double(gca),'FontSize', 12);

% Show #trials over time
numtrials_oversessions(ratname, 'from',from,'to',to,'mark_breaks',1,'mark_manips',0);
set(double(gcf),'Position',[0 11 630 200]);
sub__shrinktitle(double(gcf),12);


% if dur rat, look at trial length bias
ratrow = rat_task_table(ratname);
t=ratrow{1,2};
if strcmpi(t(1:3),'dur')
    triallen_influence(ratname,'from',from,'to',to);
else
    spl_influence(ratname, 'use_dateset','psych_before');
end;
set(double(gcf),'Position', [630 10 600 200]);
    sub__shrinktitle(double(gcf),12);

loadpsychinfo(ratname, 'infile','psych_before')
set(double(gcf),'Position',   [3   544   572   216]);

function [] = sub__shrinktitle(fig,fsize)
 t=get(double(gca),'Title');
 set(t,'FontSize', fsize);