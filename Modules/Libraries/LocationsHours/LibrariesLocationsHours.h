#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LibrariesLocationsHoursTerm;

@interface LibrariesLocationsHours : NSManagedObject

@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * status;
@property (nonatomic, copy) NSString * hoursToday;
@property (nonatomic, copy) NSString * url;
@property (nonatomic, copy) NSString * telephone;
@property (nonatomic, copy) NSString * location;
@property (nonatomic, copy) NSSet* terms;

- (BOOL)hasDetails;
- (void)updateDetailsWithDict:(NSDictionary *)dict;

+ (LibrariesLocationsHours *)libraryWithDict:(NSDictionary *)dict;
+ (void)removeAllLibraries;

@end
