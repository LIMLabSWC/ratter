function ok = send_alert_email(ratname, subject, body)
% ok = send_alert_email(ratname, subject, body)
%
% Sends an alert e-mail to the contacts listed for this rat in the rats
% table (same recipients and Gmail account as runrats' email_experimenter /
% gmail_SMTP). Credentials are read from
% PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat (SVN-tracked, never in Git),
% fields gmail_smtp_address and gmail_smtp_password.
% Returns true if at least one e-mail was handed to sendmail.

ok = false;
try
    contact = bdata(['select contact from rats where ratname="', ratname, '"']);
    if isempty(contact) || isempty(contact{1})
        fprintf(2, 'send_alert_email: no contact listed for %s\n', ratname);
        return;
    end

    config_path = which('PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat');
    if isempty(config_path)
        fprintf(2, 'send_alert_email: PASSWORD_CONFIG-DO_NOT_VERSIONCONTROL.mat not on the MATLAB path\n');
        return;
    end
    config = load(config_path);
    if ~isfield(config, 'gmail_smtp_address') || ~isfield(config, 'gmail_smtp_password')
        fprintf(2, 'send_alert_email: gmail_smtp_address / gmail_smtp_password missing in config\n');
        return;
    end

    setpref('Internet', 'SMTP_Server', 'smtp.gmail.com');
    setpref('Internet', 'E_mail', config.gmail_smtp_address);
    setpref('Internet', 'SMTP_Username', config.gmail_smtp_address);
    setpref('Internet', 'SMTP_Password', config.gmail_smtp_password);
    props = java.lang.System.getProperties;
    props.setProperty('mail.smtp.auth', 'true');
    props.setProperty('mail.smtp.starttls.enable', 'true');
    props.setProperty('mail.smtp.port', '587');

    names = strsplit(strrep(contact{1}, ' ', ''), ',');
    for i = 1:numel(names)
        if isempty(names{i}), continue; end
        try
            sendmail([names{i} '@ucl.ac.uk'], subject, body);
            ok = true;
        catch ME
            fprintf(2, 'send_alert_email: sending to %s failed: %s\n', names{i}, ME.message);
        end
    end
catch ME
    fprintf(2, 'send_alert_email: %s\n', ME.message);
end
