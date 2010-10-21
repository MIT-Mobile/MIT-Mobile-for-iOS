
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MITMobileWebAPI.h"

@interface MITMapSearchResultAnnotation : NSObject <MKAnnotation>{

	CLLocationCoordinate2D _coordinate;
	
	NSString* _architect;
	NSString* _bldgimg;
	NSString* _bldgnum;
	
	NSString* _uniqueID;
	NSString* _mailing;
	NSString* _name;
	NSString* _street;
	NSString* _city;
	NSString* _viewAngle;
	
	NSArray* _contents;
	
	NSArray* _snippets;
	
	// has the data of this object been populated yet
	BOOL _dataPopulated;
	
	NSDictionary* _info;
	
	// flag indicating if this instance was loaded from a bookmark
	BOOL _bookmark;
}

@property (nonatomic, retain) NSString* architect;
@property (nonatomic, retain) NSString* bldgimg;
@property (nonatomic, retain) NSString* bldgnum;
@property (nonatomic, retain) NSString* uniqueID;
@property (nonatomic, retain) NSString* mailing;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* street;
@property (nonatomic, retain) NSString* viewAngle;
@property (nonatomic, retain) NSArray* contents;
@property (nonatomic, retain) NSArray* snippets;
@property (nonatomic, retain) NSString* city;

@property (nonatomic, retain) NSDictionary* info;

@property BOOL dataPopulated;
@property BOOL bookmark;

+(void) executeServerSearchWithQuery:(NSString *)query jsonDelegate: (id<JSONLoadedDelegate>)delegate object:(id)object;

// initialize the annotation with data from the MIT webservice.
-(id) initWithInfo:(NSDictionary*)info;

-(id) initWithCoordinate:(CLLocationCoordinate2D) coordinate;

@end
