module.exports.prepare = function(config, replaceInFiles, moveFile, runProcessThrowError) {

    var path = require('path');

    // Values in template
    var templateAppName = 'iOSNativeTemplate';
    var templateCompanyId = 'com.salesforce.iosnativetemplate';
    var templateOrgName = 'iOSNativeTemplateOrganizationName';
    var templateAppId = '3MVG9Iu66FKeHhINkB1l7xt7kR8czFcCTUhgoA8Ol2Ltf1eYHOU4SqQRSEitYFDUpqRWcoQ2.dBv_a1Dyu5xa';
    var templateCallbackUri = 'testsfdc =///mobilesdk/detect/oauth/done';

    // Key files
    var templatePodfile = 'Podfile';
    var templatePackageFile = 'package.json';
    var templateProjectDir = templateAppName + '.xcodeproj';
    var templateProjectFile = path.join(templateProjectDir, 'project.pbxproj');
    var templateSchemeFile = path.join(templateAppName + '.xcodeproj', 'xcshareddata', 'xcschemes', templateAppName + '.xcscheme');
    var templatePrefixFile = path.join(templateAppName, templateAppName + '-Prefix.pch');
    var templateInfoFile = path.join(templateAppName, templateAppName + '-Info.plist');
    var templateEntitlementsFile = path.join(templateAppName, templateAppName + '.entitlements');
    var templateAppDelegateFile = path.join(templateAppName, 'AppDelegate.m');

    //
    // Replace in files
    //

    // app name
    replaceInFiles(templateAppName, config.appname, [templatePodfile, templatePackageFile, templateProjectFile, templateSchemeFile, templateEntitlementsFile, templateAppDelegateFile]);

    // company id
    replaceInFiles(templateCompanyId, config.companyid, [templateInfoFile, templateEntitlementsFile]);

    // org name
    replaceInFiles(templateOrgName, config.orgname, [templateProjectFile]);

    // app id
    if (config.appid) {
        replaceInFiles(templateAppId, config.appid, [templateAppDelegateFile]);
    }
                   
    // callback uri
    if (config.callbackuri) {
        replaceInFiles(templateCallbackUri, config.callbackuri, [templateAppDelegateFile]);
    }

    //
    // Rename files
    //
    moveFile(templateSchemeFile, path.join(config.appname + '.xcodeproj', 'xcshareddata', 'xcschemes', config.appname + '.xcscheme'));
    moveFile(templatePrefixFile, path.join(config.appname, config.appname + '-Prefix.pch'));
    moveFile(templateInfoFile, path.join(config.appname, config.appname + '-Info.plist'));
    moveFile(templateEntitlementsFile, path.join(config.appname, config.appname + '.entitlements'));
    moveFile(templateProjectDir, config.appname + '.xcodeproj');

    //
    // Run npm and pod
    //
    runProcessThrowError('npm install');
    runProcessThrowError('pod install');
};
