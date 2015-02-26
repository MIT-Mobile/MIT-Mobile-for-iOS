//
//  MITShuttleTransformers.m
//  MITShuttleApi
//
//  Created by Logan Wright on 2/25/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import "MITShuttleTransformers.h"
#import "MITMapBoundingBox.h"
#import "MITMapPathSegment.h"
#import <Realm/Realm.h>

@implementation MITBoundingBoxTransformer
+ (id)transform:(NSArray *)bboxArray {
    /*
     Bounding box comes in format:
     [nwLong, nwLat, seLong, swLat]; -- Yes, it's backwards
     ie: [ -71.1049941, 42.3548358, -71.0843897, 42.3623986 ]
     */
    MITMapBoundingBox *bbox = [MITMapBoundingBox new];
    NSMutableArray *coords = [NSMutableArray array];
    for (int i = 0; i < bboxArray.count; i = i + 2) {
        MITMapCoordinate *coord = [MITMapCoordinate new];
        coord.longitude = [bboxArray[i] doubleValue];
        coord.latitude = [bboxArray[i + 1] doubleValue];
        [coords addObject:coord];
    }
    bbox.northWest = coords.firstObject;
    bbox.southEast = coords.lastObject;
    return bbox;
}
@end

@implementation MITPathSegmentsTransformer
+ (id)transform:(NSArray *)fromVal {
    
    NSMutableArray *pathSegments = [NSMutableArray array];
    for (NSArray *pathSegment in fromVal) {
        NSMutableArray *coords = [NSMutableArray array];
        for (NSArray *coordsArray in pathSegment) {
            // Coord arrays are formatted [long, lat] -- Yes, it's backwards.
            MITMapCoordinate *coord = [MITMapCoordinate new];
            coord.longitude = [coordsArray.firstObject doubleValue];
            coord.latitude = [coordsArray.lastObject doubleValue];
            [coords addObject:coord];
        }
        
        MITMapPathSegment *segment = [MITMapPathSegment new];
        [segment.coordinates addObjects:coords];
        [pathSegments addObject:segment];
    }
    
    RLMArray *arr = [[RLMArray alloc] initWithObjectClassName:[MITMapPathSegment className]];
    [arr addObjects:pathSegments];

    return arr;
}
@end
