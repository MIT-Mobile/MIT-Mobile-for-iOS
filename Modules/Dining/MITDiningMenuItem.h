#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@interface MITDiningMenuItem : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) id dietaryFlags;
@property (nonatomic, retain) NSString * itemDescription;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * station;

@end
