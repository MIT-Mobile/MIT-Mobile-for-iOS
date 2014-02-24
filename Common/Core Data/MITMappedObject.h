#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>

@protocol MITMappedObject <NSObject>
+ (RKMapping*)objectMapping;
@end