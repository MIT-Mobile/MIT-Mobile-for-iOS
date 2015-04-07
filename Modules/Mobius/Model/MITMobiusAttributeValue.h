#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusAttributeValueSet;

@interface MITMobiusAttributeValue : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) MITMobiusAttributeValueSet *valueSet;

@end
