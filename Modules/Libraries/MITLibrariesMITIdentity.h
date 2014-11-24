#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@interface MITLibrariesMITIdentity : NSObject <MITMappedObject>
@property (nonatomic, copy) NSString *shibIdentity;
@property (nonatomic, copy) NSString *username;
@property (nonatomic) BOOL isMITIdentity;
@end
