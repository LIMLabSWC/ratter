function obj = timer(varargin)
%TIMER Construct timer object.
%
%    T = TIMER constructs a timer object with default attributes.  
%
%    T = TIMER('PropertyName1',PropertyValue1, 'PropertyName2', PropertyValue2,...)
%    constructs a timer object in which the given Property name/value pairs are
%    set on the object.
%
%    Note that the property value pairs can be in any format supported by
%    the SET function, i.e., param-value string pairs, structures, and
%    param-value cell array pairs.  
% 
%    Example:
%       % To construct a timer object with a timer callback mycallback and a 10s interval:
%         t = timer('TimerFcn',@mycallback, 'Period', 10.0);
%
%
%    See also TIMER/SET, TIMER/TIMERFIND, TIMER/START, TIMER/STARTAT.

%    RDD 10/23/01
%    Copyright 2001-2005 The MathWorks, Inc.
%    $Revision: 1616 $  $Date: 2008-08-23 04:05:37 -0400 (Sat, 23 Aug 2008) $

% Create the default class.

% check for AWT
if ~isempty(javachk('awt'))
    error('MATLAB:timer:noawt',timererror('MATLAB:timer:noawt'));    
end

obj.ud = {}; % this is in support of loadobj/saveobj

if (nargin>0) && all(ishandle(varargin{1})) && all(isJavaTimer(varargin{1})) % java handle given, just wrap in OOPS
    % this flavor of the constructor is not intended to be for the end-user
    if sum(gt(size(varargin{1}),1)) > 1 % not a vector, sorry.
        error('MATLAB:timer:creatematrix',timererror('matlab:timer:creatematrix'));
    end
    obj.jobject = varargin{1}; % make a MATLAB timer object from a java timer object
    obj = class(obj,'timer');
elseif nargin>0 && isa(varargin{1},'timer') % duplicate a timer object
    % e.g., q = timer(t), where t is a timer array.
    orig = varargin{1};
    len = length(orig);
    % foreach valid object in the original timer object array...
    for lcv=1:len
        if isJavaTimer(orig.jobject(lcv))
            % for valid java timers found, make new java timer object,...
            obj.jobject(lcv) = handle(com.mathworks.timer.TimerTask);
            obj.jobject.MakeDeleteFcn(@deleteAsync);
            % duplicate copy of settable properties from the old object to the new object,and ...
            propnames = fieldnames(set(orig.jobject(lcv)));
            propvals = get(orig.jobject(lcv),propnames);
            set(obj.jobject(lcv),propnames,propvals);
            mltimerpackage('Add', obj.jobject(lcv));
        else
            obj.jobject(lcv) = orig.jobject(lcv);
        end
    end
    obj = class(obj,'timer'); % create the OOPS class
else
    % e.g., t=timer or t=timer('pn',pv,...)
    % create new java object
    obj.jobject = handle(com.mathworks.timer.TimerTask);
    % set a default name to a unique identifier, i.e., an object 'serial number'
	obj.jobject.setName(['timer-' num2str(mltimerpackage('Count'))]);
    obj.jobject.timerFcn = '';
    obj.jobject.errorFcn = '';
    obj.jobject.stopFcn = '';
    obj.jobject.startFcn = '';
	obj.jobject.MakeDeleteFcn(@deleteAsync);
    obj = class(obj,'timer');
    if (nargin>0) 
        % user gave PV pairs, so process them by calling set.
        try
            set(obj, varargin{:});
        catch
            lerr = fixlasterr;
            error(lerr{:}); %#ok
        end
    end
    % register the new object so timerfind can find it later,
	mltimerpackage('Add', obj.jobject);
end
