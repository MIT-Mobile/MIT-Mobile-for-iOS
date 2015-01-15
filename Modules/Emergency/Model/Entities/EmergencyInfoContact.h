#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@interface EmergencyInfoContact : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * contactDescription; //Named a bit oddly because 'description' conflicts with -[NSObject description]

@end
