#import <CoreData/CoreData.h>


@interface CorridorStory :  NSManagedObject
{
}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * imageWidth;
@property (nonatomic, retain) NSNumber * imageHeight;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) NSString * htmlBody;
@property (nonatomic, retain) NSString * plainBody;
@property (nonatomic, retain) NSString * affiliation;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic, retain) NSNumber * ordinality;

+ (CorridorStory *)corridorStoryWithDictionary:(NSDictionary *)aDict;

@end



