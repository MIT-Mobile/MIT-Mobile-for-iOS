#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITToursStop;

@interface MITToursDirectionsToStop : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * destinationID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * bodyHTML;
@property (nonatomic, retain) NSNumber * zoom;
@property (nonatomic, retain) id path;
@property (nonatomic, retain) MITToursStop *stop;

@end
