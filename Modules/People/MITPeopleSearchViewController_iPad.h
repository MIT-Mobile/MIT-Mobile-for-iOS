//
//  PeopleSearchViewController_iPad.h
//  MIT Mobile
//
//  Created by YevDev on 5/25/14.
//
//

#import <UIKit/UIKit.h>
#import "PersonDetails.h"

@protocol PeopleSearchViewControllerDelegate

- (void) didSelectPerson:(PersonDetails *)person;

@end

@protocol PeopleRecentsViewControllerDelegate

- (void) didSelectRecentPerson:(PersonDetails *)person;
- (void) didClearRecents;

@end

@protocol MITPeopleFavoritesViewControllerDelegate

- (void) didSelectFavoritePerson:(PersonDetails *)person;
- (void) didDismissFavoritesPopover;

@end

@interface MITPeopleSearchViewController_iPad : UIViewController<PeopleSearchViewControllerDelegate, PeopleRecentsViewControllerDelegate, MITPeopleFavoritesViewControllerDelegate>

@end
