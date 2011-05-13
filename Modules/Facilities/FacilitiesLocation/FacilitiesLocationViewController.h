//
//  FacilitiesCategoryViewController.h
//  MIT Mobile
//
//  Created by Blake Skinner on 5/12/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FacilitiesLocationDataViewController.h"

@class FacilitiesCategory;

@interface FacilitiesLocationViewController : FacilitiesLocationDataViewController {
    FacilitiesCategory *_category;
}

@property (nonatomic,retain) FacilitiesCategory* category;

@end
