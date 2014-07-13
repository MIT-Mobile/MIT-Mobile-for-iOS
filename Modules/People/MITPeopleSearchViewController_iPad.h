//
//  PeopleSearchViewController_iPad.h
//  MIT Mobile
//
//  Created by YevDev on 5/25/14.
//
//

#import <UIKit/UIKit.h>
#import "PersonDetails.h"

@protocol PeopleSearchViewControllerDelegate_

- (void) didSelectPerson:(PersonDetails *)person;

@end

@protocol PeopleRecentsViewControllerDelegate_

- (void) didSelectRecentPerson:(PersonDetails *)person;
- (void) didClearRecents;

@end

@protocol MITPeopleFavoritesViewControllerDelegate_

- (void) didSelectFavoritePerson:(PersonDetails *)person;
- (void) didDismissFavoritesPopover;

@end

@interface MITPeopleSearchViewController_iPad : UIViewController<PeopleSearchViewControllerDelegate_, PeopleRecentsViewControllerDelegate_, MITPeopleFavoritesViewControllerDelegate_>

@end
