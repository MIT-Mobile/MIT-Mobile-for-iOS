#import <Foundation/Foundation.h>
#import "MITMappedObject.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

extern NSString *const kMITLibraryClosedMessageString;

@interface MITLibrariesLibrary : NSObject <MITMappedObject, MKAnnotation, NSCoding>

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSArray *terms;
@property (nonatomic, strong) NSArray *coordinateArray;

- (NSString *)hoursStringForDate:(NSDate *)date;
- (BOOL)isOpenAtDate:(NSDate *)date;
- (BOOL)isOpenOnDayOfDate:(NSDate *)date;

@end
