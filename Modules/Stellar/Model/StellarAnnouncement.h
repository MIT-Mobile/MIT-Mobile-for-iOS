
#import <CoreData/CoreData.h>

@class StellarClass;

@interface StellarAnnouncement :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * unixDate;
@property (nonatomic, retain) NSString * short_description;
@property (nonatomic, retain) NSDate * pubDate;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) StellarClass * stellarClass;

@end



