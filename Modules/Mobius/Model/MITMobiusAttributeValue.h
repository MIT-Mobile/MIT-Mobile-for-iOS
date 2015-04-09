#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusAttribute;

@interface MITMobiusAttributeValue : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) MITMobiusAttribute *attribute;

@end
