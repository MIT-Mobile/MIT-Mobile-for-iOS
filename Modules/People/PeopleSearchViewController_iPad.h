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

@interface PeopleSearchViewController_iPad : UIViewController<PeopleSearchViewControllerDelegate>

@end
