#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@interface MITMartyObject : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * createdBy;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * modified;
@property (nonatomic, retain) NSString * modifiedBy;
@property (nonatomic, retain) NSString * name;

@end
