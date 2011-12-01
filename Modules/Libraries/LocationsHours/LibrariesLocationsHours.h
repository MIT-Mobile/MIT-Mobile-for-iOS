#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LibrariesLocationsHoursTerm;

@interface LibrariesLocationsHours : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * hoursToday;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * telephone;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSSet* terms;

- (BOOL)hasDetails;
- (void)updateDetailsWithDict:(NSDictionary *)dict;

+ (LibrariesLocationsHours *)libraryWithDict:(NSDictionary *)dict;
+ (void)removeAllLibraries;

@end
