//
//  MITMobileServerConfiguration.h
//

#import <Foundation/Foundation.h>

typedef enum {
    MITMobileWebProduction = 0,
    MITMobileWebStaging,
    MITMobileWebDevelopment
} MITMobileWebServerType;

/*!
    @function MITMobileWebGetAPISeverList
    @abstract Returns a list of all defined MIT Mobile Web API Servers
    @result an autoreleased array of NSURLs
*/
NSArray* MITMobileWebGetAPIServerList( void );


/*!
    @function MITMobileWebGetDefaultServerURL
    @abstract Returns an NSURL with the default MIT Mobile Web server
    @discussion Use this function to get a reference to an NSURL which represents the API server the app will access if the user has not indicated a previous preference.
    @result an autoreleased NSURL
*/
NSURL* MITMobileWebGetDefaultServerURL( void );


/*!
    @function MITMobileWebSetCurrentServerURL
    @abstract Changes the current API server URL
    @discussion This function globally changes the current URL used for API requests. Any URL passed to this function must exist in the array returned by @link MITMobileWebGetAPIServerList MITMobileWebGetAPIServerList @/link
    @param serverURL the URL to set
    @result YES if the API server was successfully changed, NO otherwise
*/
BOOL MITMobileWebSetCurrentServerURL(NSURL* serverURL);


/*!
    @function MITMobileWebGetCurrentServerURL
    @abstract Returns the current API server URL
    @result an autoreleased NSURL
*/
NSURL* MITMobileWebGetCurrentServerURL( void );


/*!
    @function MITMobileWebGetCurrentServerDomain
    @abstract Returns the 'host' part of the current API server URL
    @result an autoreleased NSString
*/
NSString* MITMobileWebGetCurrentServerDomain( void );


/*!
    @function MITMobileWebGetCurrentServerType
    @abstract Returns the current API server type
    @discussion This function attempts to guess the 'type' of the currently selected API server. Current there are 3 different types: development, staging and production. The servers type is currently guess by looking a specific substring in the hostname with '-dev.' being a development server and '-stage.' being a staging server (all others assumed to be production). This function should be revisited in the future to determine if there is a better way of doing this or if it's even needed
*/
MITMobileWebServerType MITMobileWebGetCurrentServerType( void );