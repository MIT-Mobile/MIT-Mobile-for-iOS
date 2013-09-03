#import <CoreData/CoreData.h>

@class TourLink;
@class TourSiteOrRoute;

@interface CampusTour :  NSManagedObject  
{
}

@property (nonatomic, copy) NSString * tourID;
@property (nonatomic, copy) NSString * summary;
@property (nonatomic, copy) NSString * moreInfo;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * feedbackSubject;
@property (nonatomic, strong) NSDate * lastModified;
@property (nonatomic, copy) NSSet* components;
@property (nonatomic, copy) NSSet* links;
@property (nonatomic, copy) NSString * startLocationHeader;

- (void)deleteCachedMedia;

@end


@interface CampusTour (CoreDataGeneratedAccessors)
- (void)addComponentsObject:(TourSiteOrRoute *)value;
- (void)removeComponentsObject:(TourSiteOrRoute *)value;
- (void)addComponents:(NSSet *)value;
- (void)removeComponents:(NSSet *)value;

@end

