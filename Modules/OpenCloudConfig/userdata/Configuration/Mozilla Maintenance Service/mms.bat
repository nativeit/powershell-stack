Rem Refrence https://support.mozilla.org/en-US/kb/what-mozilla-maintenance-service
Rem Refrence https://bugzilla.mozilla.org/show_bug.cgi?id=1241225

Set workingdir="C:\DSC\MozillaMaintenance"

"%workingdir%\maintenanceservice_installer.exe"

certutil.exe -addstore Root %workingdir%\MozFakeCA.cer
certutil.exe -addstore Root %workingdir%\MozFakeCA_2017-10-13.cer
certutil.exe -addstore Root %workingdir%\MozRoot.cer

reg.exe import %workingdir%\mms.reg
