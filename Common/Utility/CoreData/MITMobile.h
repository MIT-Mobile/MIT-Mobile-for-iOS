#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>

@class MITMobileResource;

extern NSString* const MITMobileErrorDomain;
typedef NS_ENUM(NSInteger, MITMobileErrorCode) {
    MITMobileResourceNotFound = 0xFF00
};
@interface MITMobile : NSObject
@property (nonatomic,readonly) NSDictionary *resources;
@property (nonatomic,strong) RKManagedObjectStore *managedObjectStore;

/** Returns the default object manager instance

 @return The default object manager instance.
 */
+ (MITMobile*)defaultManager;

- (instancetype)init;

/** Sets the managed object store to use for CoreData-backed resources.
    If this is not set, any mappings requiring CoreData will be not be performed.

 @related RKManagedObjectStore
 */
- (void)setManagedObjectStore:(RKManagedObjectStore *)managedObjectStore;

/** Returns the resource registered for a specific route name or nil is one has not been added.
 
 @return The resource for the named route or nil
 */
- (MITMobileResource*)resourceForName:(NSString*)name;

- (void)addResource:(MITMobileResource*)resource;


- (void)getObjectsForResourceNamed:(NSString *)routeName parameters:(NSDictionary *)parameters completion:(void (^)(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error))loaded;

- (void)getObjectsForResourceNamed:(NSString *)routeName object:(id)object parameters:(NSDictionary *)parameters completion:(void (^)(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error))loaded;

- (void)getObjectsForURL:(NSURL*)url completion:(void (^)(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error))loaded;

- (void)cancelAllRequestOperationsForRequestMethod:(RKRequestMethod)requestMethod atResourcePath:(NSString *)resourcePath;

@end
