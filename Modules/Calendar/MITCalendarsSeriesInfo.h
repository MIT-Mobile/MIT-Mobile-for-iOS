#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@interface MITCalendarsSeriesInfo : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * seriesDescription;

@end
