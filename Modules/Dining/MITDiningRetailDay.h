#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@interface MITDiningRetailDay : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSDate * startTime;

@end
