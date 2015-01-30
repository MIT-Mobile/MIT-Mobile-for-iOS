#import "MobileKeychainServices.h"
#import "MITLogging.h"

NSMutableDictionary* searchDictionaryForItemIdentifier(NSString *itemIdentifier) {
    NSMutableDictionary *searchDictionary = [NSMutableDictionary dictionary];
    searchDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    searchDictionary[(__bridge id)kSecAttrService] = [itemIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    searchDictionary[(__bridge id)kSecAttrGeneric] = [itemIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    searchDictionary[(__bridge id)kSecReturnAttributes] = (__bridge id)kCFBooleanTrue;
    return searchDictionary;
}

NSDictionary* MobileKeychainFindItem(NSString *itemIdentifier, BOOL returnData) {
    NSMutableDictionary *searchDictionary = searchDictionaryForItemIdentifier(itemIdentifier);

    CFDictionaryRef cfquery = (__bridge_retained CFDictionaryRef)searchDictionary;
    CFDictionaryRef itemAttrs = NULL;
    OSStatus error = SecItemCopyMatching(cfquery, (CFTypeRef *)&itemAttrs);
    CFRelease(cfquery);
    
    if ((error != noErr) && (error != errSecItemNotFound)) {
        DDLogCError(@"SecItemCopyMatching failed with error %d", (int)error);
    } else if (returnData) {
        [searchDictionary setObject:(id)kCFBooleanTrue
                             forKey:(__bridge id)kSecReturnData];
        [searchDictionary removeObjectForKey:(__bridge id)kSecReturnAttributes];
        
        CFDataRef passwordData = nil;
        error = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, (CFTypeRef *)&passwordData);
        
        if (error == noErr) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:(__bridge NSDictionary *)itemAttrs];
            NSString *pwString = [[NSString alloc] initWithData:(__bridge NSData *)passwordData
                                                       encoding:NSUTF8StringEncoding];
            dict[(__bridge id)kSecValueData] = pwString;
            itemAttrs = (__bridge_retained CFDictionaryRef)[[NSDictionary alloc] initWithDictionary:dict];
        }
    }
    
    if ((error != noErr) && (error != errSecItemNotFound)) {
        DDLogCError(@"SecItemCopyMatching failed with error %d", (int)error);
    }
    
    NSDictionary *returnDict = (__bridge NSDictionary *)itemAttrs;
    if (itemAttrs != NULL) {
        CFRelease(itemAttrs);
    }
    return returnDict;
}

NSDictionary* MobileKeychainAttributesForItem(NSString *itemIdentifier) {
    NSMutableDictionary *searchDictionary = searchDictionaryForItemIdentifier(itemIdentifier);
    
    CFDictionaryRef result = nil;
    OSStatus error = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, (CFTypeRef *)&result);
    
    if (error != noErr) {
        DDLogCError(@"SecItemCopyMatching failed with error %d", (int)error);
        return nil;
    } else {
        return (__bridge NSDictionary *)result;
    }
}

BOOL MobileKeychainSetItem(NSString *itemIdentifier, NSString *username, NSString *password) {
    NSDictionary *item = MobileKeychainFindItem(itemIdentifier, YES);
    OSStatus error = noErr;
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    if (password) {
        attributes[(__bridge id)kSecValueData] = [password dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSMutableDictionary *searchDictionary = [NSMutableDictionary dictionary];
    searchDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    searchDictionary[(__bridge id)kSecAttrService] = [itemIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    searchDictionary[(__bridge id)kSecAttrGeneric] = [itemIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    if (item) {
        
        if ([username length] > 0) {
            attributes[(__bridge id)kSecAttrAccount] = [username dataUsingEncoding:NSUTF8StringEncoding];
        }
        CFDictionaryRef cfquery = (__bridge_retained CFDictionaryRef)searchDictionary;
        CFDictionaryRef cfattr = (__bridge_retained CFDictionaryRef)attributes;
        error = SecItemUpdate(cfquery, cfattr);
        CFRelease(cfquery);
        CFRelease(cfattr);
    } else {
        if ([username length] > 0) {
            [attributes addEntriesFromDictionary:searchDictionary];
            attributes[(__bridge id)kSecAttrAccount] = [username dataUsingEncoding:NSUTF8StringEncoding];
#if !defined (TARGET_IPHONE_SIMULATOR)
            attributes[(__bridge id)kSecAttrAccessGroup] = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] dataUsingEncoding:NSUTF8StringEncoding];
#endif
            CFDictionaryRef cfattr = (__bridge_retained CFDictionaryRef)attributes;
            error = SecItemAdd(cfattr, NULL);
            CFRelease(cfattr);
            
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
    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword
                         forKey:(__bridge id)kSecClass];
    [searchDictionary setObject:itemIdentifier
                         forKey:(__bridge id)kSecAttrService];
    
    error = SecItemDelete((__bridge CFDictionaryRef)searchDictionary);
    
    return (error == noErr);
}
