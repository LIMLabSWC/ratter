function compnames = get_compnames


[ip_addr,rigid]=bdata('select ip_addr, rigid from ratinfo.riginfo order by rigid');
%compnames=cell(numel(rigid),3);
compnames = cell(0,3);
for rx=1:numel(rigid)
    if rigid(rx)==5 || rigid(rx)==6
        compnames(end+1,:)={'' num2str(rigid(rx)) ''}; %#ok<AGROW>
    elseif rigid(rx) > 30
        continue;
    else
        compnames(end+1,:)={ip_addr{rx} num2str(rigid(rx)) ip_addr{rx}}; %#ok<AGROW>
    end
end

compnames(end+1,:)={'128.112.161.36' '31' '128.112.161.36'};


return;
%/
compnames = {'mol-72a8d5',       '1','mol-72a8d5';...      %rig 1
             'brodyrigxp02',     '2','brodyrigxp02';...    %rig 2
             'brodyrigxp03',     '3','brodyrigxp03';...    %rig 3
             'brodyrigxp04',     '4','brodyrigxp04';...    %rig 4
             '',                 '5','';...                %rig 4
             '',                 '6','';...                %rig 4
             'brodyrigxp07',     '7','brodyrigxp07';...    %rig 7
             'mol-brodyrigxp08', '8','mol-brodyrigxp08';...%rig 8
             'brodyrigxp09',     '9','brodyrigxp09';...    %rig 9
             'mol-brodyws2k801','10','brodyrigxp13';...    %rig 10
             'brodyrigxp11',    '11','brodyrigxp11';...    %rig 11
             'brodyrigxp12',    '12','brodyrigxp12';...    %rig 12
             'mol-brodyws2k802','13','brodyrigxp10';...    %rig 13
             'brodyrigxp14',    '14','brodyrigxp14';...    %rig 14
             'brodyrig18',      '15','mol-72bb48';...      %rig 15
             'brodyrigxp16',    '16','brodyrigxp16';...    %rig 16
             'brodyrigxp17',    '17','brodyrigxp17';...    %rig 17
             'mol-72ba3d',      '18','mol-72ba3d';...      %rig 18
             'brodyrigxp19',    '19','brodyrigxp19';...    %rig 19
             'brodyrigxp20',    '20','brodyrigxp20';...    %rig 20
             'brodyrigxp21',    '21','brodyrigxp21';...    %rig 21
             'brodyrigxp22',    '22','brodyrigxp22';...    %rig 22
             'brodyrigxp23',    '23','brodyrigxp23';...    %rig 23
             'brodyrigxp24',    '24','brodyrigxp24';...    %rig 24
             'mol-72ba56',      '25','mol-72ba56';...      %rig 25
             'brodyrigxp26',    '26','brodyrigxp26';...    %rig 26
             'brodyrigxp27',    '27','brodyrigxp27';...    %rig 27
             'brodyrigxp28',    '28','brodyrigxp28';...    %rig 28
             'brodyrigxp29',    '29','brodyrigxp29';...    %rig 29
             'brodyrigxp30',    '30','brodyrigxp30';...    %rig 30
             'brodyrigtech',    '31','brodyrigtech'};      %tech computer
         
         