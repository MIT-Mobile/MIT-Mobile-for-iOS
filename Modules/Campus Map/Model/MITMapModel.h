#ifndef _MIT_MAP_MODEL_H_
#define _MIT_MAP_MODEL_H_

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>

#import "MITMapModelController.h"
#import "MITMapCategory.h"
#import "MITMapPlace.h"

typedef void (^MITMapPlaceSelectionHandler)(NSOrderedSet *selectedPlaces, NSError *error);

#endif
