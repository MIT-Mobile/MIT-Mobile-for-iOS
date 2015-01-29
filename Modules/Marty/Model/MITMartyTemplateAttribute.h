#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMartyResourceAttribute, MITMartyTemplate;

@interface MITMartyTemplateAttribute : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * fieldType;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSNumber * required;
@property (nonatomic, retain) NSNumber * sort;
@property (nonatomic, retain) NSString * widgetType;
@property (nonatomic, retain) MITMartyResourceAttribute *attributeValues;
@property (nonatomic, retain) MITMartyTemplate *template;

@end
