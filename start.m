function start()
name = 'pmls_engine';
if ~(matlab.engine.isEngineShared && strcmp(matlab.engine.engineName, name))
    matlab.engine.shareEngine(name);
    if ~(matlab.engine.isEngineShared && strcmp(matlab.engine.engineName, name))
        disp('Cannot start engine');
        return
    end
end
disp('Wellcome!');
disp('PMLS started successfully. You can connect to pmls engine from our Blender add-on');
p = mfilename('fullpath');
type([fileparts(p), '/pmls_core/README.md']);
end
