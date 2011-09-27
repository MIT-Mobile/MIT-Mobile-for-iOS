extern NSString * const TwitterOAuthConsumerKey;
extern NSString * const TwitterOAuthConsumerSecret;

extern NSString * const FacebookAPIKey;
extern NSString * const FacebookAPISecret;


/*!
 @var MobileAPIServers
 @abstract An array of URL strings which defines the allowable mobile API servers
 @discussion This array is used in the MITMobileServerConfiguration
    functions to define the list of allowable API servers. Index 0 is assumed to
    be the default server unless MobileAPI_DefaultServerIndex is defined
    otherwise. There must be at least one valid URL.
*/
extern NSString * const MobileAPIServers[];

/*!
 @defined MobileAPI_DefaultServerIndex
 @abstract Used in conjunction with the MobileAPIServers array to identify the default server
 @discussion This value defines the index into the MobileAPIServers which should be considered
    the default server. The index is zero-based and if a value is not defined '0' will be used.
    Setting the index to a value that is out of the array's bounds will result in undefined
    behavior.
*/
#ifdef DEBUG
#define MobileAPI_DefaultServerIndex 1
#else
#define MobileAPI_DefaultServerIndex 0
#endif