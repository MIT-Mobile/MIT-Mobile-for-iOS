
#import <CoreData/CoreData.h>

@class StellarAnnouncement;

@interface StellarAnnouncementDetail :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) StellarAnnouncement * announcement;

@end



