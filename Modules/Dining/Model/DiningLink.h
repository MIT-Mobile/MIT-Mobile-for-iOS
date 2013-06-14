#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DiningRoot;

@interface DiningLink : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * ordinality;
@property (nonatomic, retain) DiningRoot *root;

+ (DiningLink *)newLinkWithDictionary:(NSDictionary *)dict;

@end
