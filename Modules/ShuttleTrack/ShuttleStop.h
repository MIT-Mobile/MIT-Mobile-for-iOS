#import <Foundation/Foundation.h>


@interface ShuttleStop : NSObject {
    
	// title of this stop
	NSString* _title;
    
	// id of this stop
	NSString* _stopID;
	
	// latitude of this stop
	double _latitude;
	
	// longitude of this stop
	double _longitude;
	
	// routes that run through this stop
	NSArray* _routes;
	
	NSInteger _nextScheduled; // timestamp
	
	// has the data of this object been populated yet
	BOOL _dataPopulated;
	
	NSString* _direction;
	
	// array of path points (lat/lon pairs)
	NSArray* _path;
	
	BOOL _upcoming;
	
}

- (id)initWithDictionary:(NSDictionary *)aDict;


@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *stopID;
@property double latitude;
@property double longitude;
@property (nonatomic, retain) NSString* direction;
@property (nonatomic, retain) NSArray* path;


@property (nonatomic, retain) NSArray* routes;

@property NSInteger nextScheduled;
@property (readonly) NSDate *nextScheduledDate;
@property BOOL upcoming;

@property BOOL dataPopulated;

@end
