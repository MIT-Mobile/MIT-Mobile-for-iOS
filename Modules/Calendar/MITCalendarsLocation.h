#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@interface MITCalendarsLocation : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * locationDescription;
@property (nonatomic, retain) NSString * roomNumber;
@property (nonatomic, retain) id coordinates;

@end
