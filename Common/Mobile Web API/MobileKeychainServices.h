#import <Foundation/Foundation.h>
#import <Security/Security.h>

NSDictionary* MobileKeychainFindItem(NSString *itemIdentifier, BOOL returnData);
NSDictionary* MobileKeychainAttributesForItem(NSString *itemIdentifier);
BOOL MobileKeychainSetItem(NSString *itemIdentifier, NSString *username, NSString *password);
BOOL MobileKeychainDeleteItem(NSString *itemIdentifier);