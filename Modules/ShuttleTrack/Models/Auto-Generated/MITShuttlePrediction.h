//
//  MITShuttlePrediction.h
//  MIT Mobile
//
//  Created by Mark Daigneault on 5/16/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITShuttlePredictionList, MITShuttleStop;

@interface MITShuttlePrediction : NSManagedObject

@property (nonatomic, retain) NSNumber * seconds;
@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSString * vehicleId;
@property (nonatomic, retain) MITShuttlePredictionList *list;
@property (nonatomic, retain) MITShuttleStop *stop;

@end
