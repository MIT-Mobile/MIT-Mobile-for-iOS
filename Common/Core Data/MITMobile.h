#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>

@class MITMobileResource;

@interface MITMobile : NSObject
@property (nonatomic,readonly) NSDictionary *resources;

+ (MITMobile*)defaultManager;

- (instancetype)init;
- (void)setManagedObjectStore:(RKManagedObjectStore *)managedObjectStore;

- (MITMobileResource*)resourceForName:(NSString*)name;
- (void)addResource:(MITMobileResource*)resource;

- (void)getObjectsForResourceNamed:(NSString *)routeName object:(id)object parameters:(NSDictionary *)parameters completion:(void (^)(RKMappingResult *result, NSError *error))loaded;
@end
