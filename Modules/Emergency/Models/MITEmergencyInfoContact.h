#import <Foundation/Foundation.h>
#import "MITMappedObject.h"

@interface MITEmergencyInfoContact : NSObject <MITMappedObject>

@property (nonatomic, strong) NSString *descriptionText; //Named a bit oddly because 'description' conflicts with -[NSObject description]
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *phone;

@end
