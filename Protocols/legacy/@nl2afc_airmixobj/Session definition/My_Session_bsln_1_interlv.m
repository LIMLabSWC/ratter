
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ------------ STAGE SEPARATOR ------- (do not edit this line)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- STAGE NAME: --- (do not edit this line)
Start Basline

% --- VAR NAMES: --- (do not edit this line)


% --- TRAINING STRING: --- (do not edit this line)
BlockControl_block_update.value = 3;
OdorSection_mix_ID.value_callback = 1;

% --- COMPLETION STRING: --- (do not edit this line)
1




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ------------ STAGE SEPARATOR ------- (do not edit this line)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- STAGE NAME: --- (do not edit this line)
Basline 1

% --- VAR NAMES: --- (do not edit this line)


% --- TRAINING STRING: --- (do not edit this line)


% --- COMPLETION STRING: --- (do not edit this line)
BlockControl_trial_count>= BlockControl_block_size && BlockControl_blk_scr(value(BlockControl_block_count)-1) >= 80



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ------------ STAGE SEPARATOR ------- (do not edit this line)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- STAGE NAME: --- (do not edit this line)
Distractor_priming

% --- VAR NAMES: --- (do not edit this line)


% --- TRAINING STRING: --- (do not edit this line)
OdorSection_mix_ID.value_callback = 2;


% --- COMPLETION STRING: --- (do not edit this line)
BlockControl_trial_count>= BlockControl_block_size




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ------------ STAGE SEPARATOR ------- (do not edit this line)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- STAGE NAME: --- (do not edit this line)
Init Interleaved 1

% --- VAR NAMES: --- (do not edit this line)


% --- TRAINING STRING: --- (do not edit this line)
BlockControl_block_update.value_callback = 4;
BlockControl_mixid_rept.value = 1;             BlockControl_repts.value_callback = 80;
BlockControl_mixid_rept.value = 2;             BlockControl_repts.value_callback = 320;


% --- COMPLETION STRING: --- (do not edit this line)
1




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ------------ STAGE SEPARATOR ------- (do not edit this line)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- STAGE NAME: --- (do not edit this line)
Interleaved stage 1

% --- VAR NAMES: --- (do not edit this line)


% --- TRAINING STRING: --- (do not edit this line)



% --- COMPLETION STRING: --- (do not edit this line)
BlockControl_n_interlv_trials_left <= 1;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ------------ STAGE SEPARATOR ------- (do not edit this line)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- STAGE NAME: --- (do not edit this line)
End of Session

% --- VAR NAMES: --- (do not edit this line)


% --- TRAINING STRING: --- (do not edit this line)
BlockControl_block_update.value = 2;


% --- COMPLETION STRING: --- (do not edit this line)
0


