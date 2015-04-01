#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>

@class MITMobiusResource;

@interface MITMobiusRoomObject : NSObject <MKAnnotation>

@property (nonatomic, copy) NSString * roomName;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, copy) NSOrderedSet *resources;
@property (nonatomic) NSInteger index;
@end
