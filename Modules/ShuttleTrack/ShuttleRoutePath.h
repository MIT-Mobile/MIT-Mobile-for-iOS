//
//  ShuttleRoutePath.h
//  MIT Mobile
//
//  Created by admin on 6/17/13.
//
//

#import <Foundation/Foundation.h>

@interface ShuttleRoutePath : NSObject
{
    NSArray *_bbox;
    NSMutableArray *_segments;
    double _minLat;
    double _minLon;
    double _maxLat;
    double _maxLon;
}

- (void)updateInfo:(NSDictionary *)vehiclesInfo;
- (id)initWithDictionary:(NSDictionary *)dict;

@property NSMutableArray *segments;
@property double minLat;
@property double minLon;
@property double maxLat;
@property double maxLon;

@end
