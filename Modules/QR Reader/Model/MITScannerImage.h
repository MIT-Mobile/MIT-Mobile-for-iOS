#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MITScannerImage : NSManagedObject

@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) NSNumber * orientation;

@end
