//
//  MITPeopleSearchRootViewController.h
//  MIT Mobile
//
//  Created by Yev Motov on 7/12/14.
//
//

#import <UIKit/UIKit.h>
#import "PersonDetails.h"

@protocol MITPeopleSearchViewControllerDelegate

- (void) didSelectPerson:(PersonDetails *)person;

@end

@protocol MITPeopleRecentsViewControllerDelegate

- (void) didSelectRecentPerson:(PersonDetails *)person;
- (void) didClearRecents;

@end

@protocol MITPeopleFavoritesViewControllerDelegate

- (void) didSelectFavoritePerson:(PersonDetails *)person;
- (void) didDismissFavoritesPopover;

@end

@interface MITPeopleSearchRootViewController : UIViewController

@end
