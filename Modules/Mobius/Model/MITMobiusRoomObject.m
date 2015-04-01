#import "MITMobiusRoomObject.h"
#import "MITMobiusResource.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

@implementation MITMobiusRoomObject
@synthesize resources = _resources;

#pragma mark MKAnnotation

- (NSString*)title
{
    return self.roomName;
}

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
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

@end
