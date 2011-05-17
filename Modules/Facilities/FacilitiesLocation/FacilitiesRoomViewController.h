//
//  FacilitiesCategoryViewController.h
//  MIT Mobile
//
//  Created by Blake Skinner on 5/12/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FacilitiesLocationDataViewController.h"

@class FacilitiesLocation;

@interface FacilitiesRoomViewController : FacilitiesLocationDataViewController {
    FacilitiesLocation *_location;
}
@property (nonatomic,retain) FacilitiesLocation* location;

@end
