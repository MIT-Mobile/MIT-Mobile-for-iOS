#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusResourceAttribute, MITMobiusTemplate;

@interface MITMobiusTemplateAttribute : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * fieldType;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSNumber * required;
@property (nonatomic, retain) NSNumber * sort;
@property (nonatomic, retain) NSString * widgetType;
@property (nonatomic, retain) MITMobiusResourceAttribute *attributeValues;
@property (nonatomic, retain) MITMobiusTemplate *template;

@end
