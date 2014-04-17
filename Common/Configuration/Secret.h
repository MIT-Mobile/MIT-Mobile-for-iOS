
extern NSString * const FacebookAppId;
extern NSString * const FacebookAPIKey;
extern NSString * const FacebookAPISecret;
extern NSString * const MITApplicationTestFlightToken;


/*!
 @var MobileAPIServers
 @abstract An array of URL strings which defines the allowable mobile API servers
 @discussion This array is used in the MITMobileServerConfiguration
    functions to define the list of allowable API servers. Index 0 is assumed to
    be the default server unless MITMobileServerConfigurationDefaultIndex is defined
    otherwise. There must be at least one valid URL.
*/
extern NSString * const MobileAPIServers[];

/*!
 @defined MITMobileServerConfigurationDefaultIndex
 @abstract Used in conjunction with the MobileAPIServers array to identify the default server
 @discussion This value defines the index into the MobileAPIServers which should be considered
    the default server. The index is zero-based and if a value is not defined '0' will be used.
    Setting the index to a value that is out of the array's bounds will result in undefined
    behavior.
*/
extern NSUInteger const MITMobileServerConfigurationDefaultIndex;