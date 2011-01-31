#import <CoreData/CoreData.h>

@class FeatureLink;

@interface FeatureSection :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * ordinality;
@property (nonatomic, retain) NSSet* links;

+ (FeatureSection *)featureSectionWithTitle:(NSString *)aTitle;

@end


@interface FeatureSection (CoreDataGeneratedAccessors)
- (void)addLinksObject:(FeatureLink *)value;
- (void)removeLinksObject:(FeatureLink *)value;
- (void)addLinks:(NSSet *)value;
- (void)removeLinks:(NSSet *)value;

@end

