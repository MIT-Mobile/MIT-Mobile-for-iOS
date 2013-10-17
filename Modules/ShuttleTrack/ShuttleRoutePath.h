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

/**
 Array of segments where a segment is a list of CLLocation objects that represents a path from the one stop to another.
 Segments are not sorted to build path from the first stop to the last.
 */
@property (nonatomic, strong) NSMutableArray *segments;
@property double minLat;
@property double minLon;
@property double maxLat;
@property double maxLon;

@end
