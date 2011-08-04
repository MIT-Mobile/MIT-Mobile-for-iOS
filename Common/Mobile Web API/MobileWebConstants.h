
/* Touchstone/Shibboleth-related error domain */
extern NSString * const MobileWebErrorDomain;
extern NSString * const MobileWebTouchstoneErrorDomain;

enum {
    MobileWebUnknownError = 0,
    MobileWebTouchstoneError,
    MobileWebSAMLError,
    MobileWebUserCanceled
};