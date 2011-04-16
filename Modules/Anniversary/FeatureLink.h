#import <CoreData/CoreData.h>

@class FeatureSection;

@interface FeatureLink :  NSManagedObject  
{
}

@property (nonatomic, retain) FeatureSection * featureSection;
@property (nonatomic, retain) NSString * featureID;
@property (nonatomic, retain) NSString * tintColor;
@property (nonatomic, retain) NSString * titleColor;
@property (nonatomic, retain) NSString * arrowColor;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSString * photoURL;
@property (nonatomic, retain) NSNumber * photoWidth;
@property (nonatomic, retain) NSNumber * photoHeight;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * sortOrder;

@property (nonatomic, readonly) CGSize size;

+ (FeatureLink *)featureLinkWithDictionary:(NSDictionary *)aDict;

@end