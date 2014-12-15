#import "MobileKeychainServices.h"
#import "MITLogging.h"

NSDictionary* MobileKeychainFindItem(NSString *itemIdentifier, BOOL returnData) {
    NSMutableDictionary *searchDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
    
    [searchDictionary setObject:(id)kSecClassGenericPassword
                         forKey:(id)kSecClass];
    [searchDictionary setObject:(id)[itemIdentifier dataUsingEncoding:NSUTF8StringEncoding]
                         forKey:(id)kSecAttrGeneric];
    [searchDictionary setObject:(id)itemIdentifier
                         forKey:(id)kSecAttrService];
    [searchDictionary setObject:(id)kCFBooleanTrue
                         forKey:(id)kSecReturnAttributes];

    NSDictionary *itemAttrs = nil;
    OSStatus error = SecItemCopyMatching((CFDictionaryRef)searchDictionary, (CFTypeRef*)&itemAttrs);
    
    if ((error != noErr) && (error != errSecItemNotFound)) {
        DDLogCError(@"SecItemCopyMatching failed with error %d", (int)error);
    } else if (returnData) {
        [searchDictionary setObject:(id)kCFBooleanTrue
                             forKey:(id)kSecReturnData];
        [searchDictionary removeObjectForKey:(id)kSecReturnAttributes];
        
        NSData *passwordData = nil;
        error = SecItemCopyMatching((CFDictionaryRef)searchDictionary, (CFTypeRef*)&passwordData);
        
        if (error == noErr) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:itemAttrs];
            NSString *pwString = [[NSString alloc] initWithData:passwordData
                                                       encoding:NSUTF8StringEncoding];
            [dict setObject:pwString
                     forKey:(id)kSecValueData];
            
            [pwString release];
            [itemAttrs release];
            itemAttrs = [[NSDictionary alloc] initWithDictionary:dict];
        }
    }
    
    if ((error != noErr) && (error != errSecItemNotFound)) {
        DDLogCError(@"SecItemCopyMatching failed with error %d", (int)error);
    }
    
    return [itemAttrs autorelease];
}

NSDictionary* MobileKeychainAttributesForItem(NSString *itemIdentifier) {
    NSMutableDictionary *searchDictionary = [NSMutableDictionary dictionary];
    
    [searchDictionary setObject:(id)kSecClassGenericPassword
                         forKey:(id)kSecClass];
    [searchDictionary setObject:(id)itemIdentifier
                         forKey:(id)kSecAttrService];
    [searchDictionary setObject:(id)[itemIdentifier dataUsingEncoding:NSUTF8StringEncoding]
                         forKey:(id)kSecAttrGeneric];
    [searchDictionary setObject:(id)kSecReturnAttributes
                         forKey:(id)kCFBooleanTrue];
    
    NSDictionary *result = nil;
    OSStatus error = SecItemCopyMatching((CFDictionaryRef)searchDictionary, (CFTypeRef*)&result);
    
    if (error != noErr) {
        DDLogCError(@"SecItemCopyMatching failed with error %d", (int)error);
        return nil;
    } else {
        return [result autorelease];
    }
}

BOOL MobileKeychainSetItem(NSString *itemIdentifier, NSString *username, NSString *password) {
    NSDictionary *item = MobileKeychainFindItem(itemIdentifier, YES);
    OSStatus error = noErr;
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    if (password) {
        [attributes setObject:(id)[password dataUsingEncoding:NSUTF8StringEncoding]
                       forKey:(id)kSecValueData];
    }
    
    if (item) {
        NSMutableDictionary *searchDictionary = [NSMutableDictionary dictionary];
        [searchDictionary setObject:(id)kSecClassGenericPassword
                             forKey:(id)kSecClass];
        [searchDictionary setObject:(id)itemIdentifier
                             forKey:(id)kSecAttrService];
        [searchDictionary setObject:(id)[itemIdentifier dataUsingEncoding:NSUTF8StringEncoding]
                             forKey:(id)kSecAttrGeneric];
        
        if ([username length] > 0) {
            [attributes setObject:(id)username
                           forKey:(id)kSecAttrAccount];
        }
        
        error = SecItemUpdate((CFDictionaryRef)searchDictionary, (CFDictionaryRef)attributes);
    } else {
        if ([username length] > 0) {
            [attributes setObject:(id)kSecClassGenericPassword
                           forKey:(id)kSecClass];
            [attributes setObject:(id)itemIdentifier
                           forKey:(id)kSecAttrService];
            [attributes setObject:(id)[itemIdentifier dataUsingEncoding:NSUTF8StringEncoding]
                           forKey:(id)kSecAttrGeneric];
            [attributes setObject:(id)username
                           forKey:(id)kSecAttrAccount];
#if !defined (TARGET_IPHONE_SIMULATOR)
            [attributes setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]
                           forKey:(id)kSecAttrAccessGroup];
#endif
            error = SecItemAdd((CFDictionaryRef)attributes, NULL);
        } else {
            return NO;
        }
    }
    
    if (error != noErr) {
        DDLogCError(@"Item add failed with error %d", (int)error);
    }
    
    return (error == noErr);
}


BOOL MobileKeychainDeleteItem(NSString *itemIdentifier) {
    OSStatus error = noErr;
    NSMutableDictionary *searchDictionary = [NSMutableDictionary dictionary];
    [searchDictionary setObject:(id)kSecClassGenericPassword
                         forKey:(id)kSecClass];
    [searchDictionary setObject:(id)itemIdentifier
                         forKey:(id)kSecAttrService];
    
    error = SecItemDelete((CFDictionaryRef)searchDictionary);
    
    return (error == noErr);
}
