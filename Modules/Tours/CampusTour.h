#import <CoreData/CoreData.h>

@class TourLink;
@class TourSiteOrRoute;

@interface CampusTour :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * tourID;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * moreInfo;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * feedbackSubject;
@property (nonatomic, retain) NSDate * lastModified;
@property (nonatomic, retain) NSSet* components;
@property (nonatomic, retain) NSSet* links;
@property (nonatomic, retain) NSString * startLocationHeader;

- (void)deleteCachedMedia;

@end


@interface CampusTour (CoreDataGeneratedAccessors)
- (void)addComponentsObject:(TourSiteOrRoute *)value;
- (void)removeComponentsObject:(TourSiteOrRoute *)value;
- (void)addComponents:(NSSet *)value;
- (void)removeComponents:(NSSet *)value;

@end

