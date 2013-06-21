//
//  ShuttleRoutePath.m
//  MIT Mobile
//
//  Created by admin on 6/17/13.
//
//

#import "ShuttleRoutePath.h"
#import <CoreLocation/CoreLocation.h>

@implementation ShuttleRoutePath

@synthesize segments = _segments;
@synthesize minLat = _minLat;
@synthesize minLon = _minLon;
@synthesize maxLat = _maxLat;
@synthesize maxLon = _maxLon;

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
	if (self != nil) {
		[self updateInfo:dict];
	}
	return self;
}

- (void)updateInfo:(NSDictionary *)pathInfo
{
    NSArray *bbox = [pathInfo objectForKey:@"bbox"];
    self.segments = [[NSMutableArray alloc] init];
    NSArray *jSegments = [pathInfo  objectForKey:@"segments"];
    for (NSArray *segment in jSegments)
    {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[[segment objectAtIndex:1] doubleValue] longitude:[[segment objectAtIndex:0] doubleValue]];
        [self.segments addObject:location];
    }
    
    if([bbox count] == 4)
    {
        _minLat = [[bbox objectAtIndex:1]doubleValue];
        _minLon = [[bbox objectAtIndex:0]doubleValue];
        _maxLat = [[bbox objectAtIndex:3]doubleValue];
        _maxLon = [[bbox objectAtIndex:2]doubleValue];
    }
    
}

@end
