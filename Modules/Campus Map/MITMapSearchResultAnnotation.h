
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MITMobileWebAPI.h"

@interface MITMapSearchResultAnnotation : NSObject <MKAnnotation>
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString* architect;
@property (nonatomic, copy) NSString* bldgimg;
@property (nonatomic, copy) NSString* bldgnum;
@property (nonatomic, copy) NSString* uniqueID;
@property (nonatomic, copy) NSString* mailing;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* street;
@property (nonatomic, copy) NSString* viewAngle;
@property (nonatomic, copy) NSArray* contents;
@property (nonatomic, copy) NSArray* snippets;
@property (nonatomic, copy) NSString* city;
@property (nonatomic, copy) NSDictionary* info;

@property BOOL dataPopulated;
@property BOOL bookmark;

+(void) executeServerSearchWithQuery:(NSString *)query jsonDelegate: (id<JSONLoadedDelegate>)delegate object:(id)object;

// initialize the annotation with data from the MIT webservice.
-(id) initWithInfo:(NSDictionary*)info;

-(id) initWithCoordinate:(CLLocationCoordinate2D) coordinate;

@end
