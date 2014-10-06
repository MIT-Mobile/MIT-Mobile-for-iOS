#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITCalendarsEvent;

@interface MITCalendarsSeriesInfo : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * seriesDescription;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) MITCalendarsEvent *event;

@end