#import "MITMobiusRoomObject.h"
#import "MITMobiusResource.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

@implementation MITMobiusRoomObject
@synthesize resources = _resources;
@synthesize coordinate = _coordinate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _coordinate = kCLLocationCoordinate2DInvalid;
    }

    return self;
}

#pragma mark MKAnnotation

- (NSString*)title
{
    return self.roomName;
}

- (void)setResources:(NSOrderedSet *)resources
{
    if (resources) {
        __block NSMutableOrderedSet *objectIDs = [[NSMutableOrderedSet alloc] init];
        [resources enumerateObjectsUsingBlock:^(NSManagedObject *object, NSUInteger idx, BOOL *stop) {
            MITClassAssert(object, [NSManagedObject class]);
            [objectIDs addObject:object.objectID];
        }];
        
        _resources = objectIDs;
    } else {
        _resources = nil;
    }

    [self _updateCoordinateCentroid];
}

- (NSOrderedSet*)resources
{
    if (_resources) {
        return [self resourcesInManagedObjectContext:[MITCoreDataController defaultController].mainQueueContext];
    } else {
        return nil;
    }
}

- (NSOrderedSet*)resourcesInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (_resources) {
        __block NSMutableOrderedSet *objects = [[NSMutableOrderedSet alloc] init];
        [managedObjectContext performBlockAndWait:^{
            [_resources enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, NSUInteger idx, BOOL *stop) {
                MITClassAssert(objectID, [NSManagedObjectID class]);
                NSError *error = nil;
                NSManagedObject *object = [managedObjectContext existingObjectWithID:objectID error:&error];
                
                if (!object) {
                    DDLogWarn(@"failed to fetch object %@: %@",objectID,error);
                } else {
                    [objects addObject:object];
                }
            }];
        }];
        
        return objects;
    } else {
        return nil;
    }
}

- (void)_updateCoordinateCentroid
{
    if (_resources.count > 0) {
        NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        managedObjectContext.parentContext = [MITCoreDataController defaultController].mainQueueContext;

        [managedObjectContext performBlockAndWait:^{
            __block MKMapPoint centroidPoint = MKMapPointMake(0, 0);
            __block NSUInteger pointCount = 0;

            NSOrderedSet *resources = [self resourcesInManagedObjectContext:managedObjectContext];
            [resources enumerateObjectsUsingBlock:^(MITMobiusResource *resource, NSUInteger idx, BOOL *stop) {
                CLLocationCoordinate2D coordinate = resource.coordinate;
                if (CLLocationCoordinate2DIsValid(coordinate)) {
                    MKMapPoint mapCoordinate = MKMapPointForCoordinate(coordinate);
                    centroidPoint.x += mapCoordinate.x;
                    centroidPoint.y += mapCoordinate.y;
                    ++pointCount;
                }
            }];

            if (pointCount > 0) {
                centroidPoint.x /= (double)(pointCount);
                centroidPoint.y /= (double)(pointCount);
                _coordinate = MKCoordinateForMapPoint(centroidPoint);
            } else {
                _coordinate = kCLLocationCoordinate2DInvalid;
            }
        }];
    } else {
        _coordinate = kCLLocationCoordinate2DInvalid;
    }

    DDLogVerbose(@"Coordinate for %@: %@",self.roomName,NSStringFromCLLocationCoordinate2D(_coordinate));
}

@end
