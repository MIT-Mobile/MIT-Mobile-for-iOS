#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesContents;

@interface FacilitiesLocation : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSDate * roomsUpdated;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* categories;
@property (nonatomic, retain) NSSet* contents;

- (NSString*)displayString;
@end
