function [handle] = h5bmread (filePath)
% See here https://stackoverflow.com/questions/5635413/how-to-convert-a-directory-into-a-package/5638104#5638104
    callerPath = evalin('caller','mfilename(''fullpath'')');        % Get full path of calling function
    name = regexp(callerPath,'\+(\w)+','tokens');                   % Parse the path string to get package directories
    name = strcat([name{:}], [repmat({'.'},1,numel(name)-1) {''}]); % Format the output
    if (~strcmp([name{:}], ''))                                     % Append name of the function to call
        name = [name{:} '.h5bm'];
    else
        name = 'h5bm';
    end
    
    func = str2func(name);                                          % Create function handle from string
    handle = func(filePath, 'H5F_ACC_RDONLY');
end