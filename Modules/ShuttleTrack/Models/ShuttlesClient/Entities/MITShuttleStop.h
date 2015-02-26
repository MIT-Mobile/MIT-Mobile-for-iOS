//
//  MITShuttleStop.h
//  MITShuttleApi
//
//  Created by Logan Wright on 2/25/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONMapping/JSONMapping.h>
#import <Realm/Realm.h>
#import <MapKit/MapKit.h>
#import "MITShuttlePrediction.h"

@class MITShuttleRoute;

@interface MITShuttleStop : RLMObject <JSONMappableObject, MKAnnotation>
@property NSString *identifier;
@property NSString *url;
@property NSString *title;
@property NSInteger stopNumber;
@property double latitude;
@property double longitude;
@property NSString *predictionsURL;
@property NSString *routeURL;

@property RLMArray<MITShuttlePrediction> *predictions;

// Needs to be set manually, can not be mapped.
@property NSString *stopAndRouteIdTuple;

// Computed
@property (readonly) NSString *routeId;
@property (readonly) MITShuttleRoute *route;
@property (readonly) MITShuttlePredictionList *predictionList;

@property (readonly) CLLocationCoordinate2D coordinate;
@end

RLM_ARRAY_TYPE(MITShuttleStop)
