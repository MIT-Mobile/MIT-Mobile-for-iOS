#import "MITTabBarController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModuleList.h"
#import "MITModule.h"
#import "MITMoreListController.h"
#import "DummyRotatingViewController.h"

#define TAB_COUNT 4

@implementation MITTabBarController

@synthesize delegate, tabBar = theTabBar, moreNavigationController, selectedViewController, activeItem, activeTabNavStack;
@dynamic viewControllers, customizableViewControllers, allItems;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        allItems = nil;
        viewControllers = nil;
        customizableViewControllers = nil;
        selectedViewController = nil;
        pendingNavigationStack = nil;
        activeItem = nil;
        activeTabNavStack = nil;
        
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.view.autoresizesSubviews = YES;
        CGFloat tabBarHeight = 49.0;
        CGFloat remainingHeight = self.view.bounds.size.height - tabBarHeight;
		
        // set up container for remainder of screen
        CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, remainingHeight);
        containingView = [[UIView alloc] initWithFrame:frame];
        containingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		// use eric's gridded background image in "more" modules
		containingView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
        [self.view addSubview:containingView];
        
        // this view should never have a superview, never be the .view of a viewcontroller
        // it exists to keep the viewcontrollers of inactive tabs from releasing their views (navigationcontrollers in our case) in response to a memory warning
        limboView = [[UIView alloc] initWithFrame:CGRectZero];
        
        // set up tab bar
        frame = CGRectMake(0, remainingHeight, self.view.bounds.size.width, tabBarHeight);
        theTabBar = [[UITabBar alloc] initWithFrame:frame];
        theTabBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        theTabBar.delegate = self;
        [self.view addSubview:theTabBar];
        
        // set up More tab's uinavigationcontroller
        moreListController = [[MITMoreListController alloc] initWithStyle:UITableViewStylePlain];
        UITabBarItem *moreTabItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMore tag:0];
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(customizeTabs)];
        moreListController.navigationItem.rightBarButtonItem = editButton;
        moreListController.navigationItem.title = @"More";
        moreListController.theTabBarController = self;

        moreNavigationController = [[UINavigationController alloc] initWithRootViewController:moreListController];
        moreNavigationController.tabBarItem = moreTabItem;
        moreNavigationController.delegate = self;
		moreNavigationController.navigationBar.barStyle = UIBarStyleBlack;

        [editButton release];
        [moreTabItem release];
//        [moreListController release];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (viewControllers) {
        // select the first tab if nothing selected
        if (!self.activeItem) {
            self.activeItem = [allItems objectAtIndex:0];
        }
        if ([allItems count] > TAB_COUNT + 1 && [allItems indexOfObject:self.activeItem] >= TAB_COUNT) {
            self.tabBar.selectedItem = moreNavigationController.tabBarItem;
            // make that tab active within the moreNavigationController
            [self showItemOnMoreList:self.activeItem];
        } else {
            self.tabBar.selectedItem = self.activeItem;
        }
        // show the selected tab's view (indexes in tabBarItems and viewControllers match up
        NSUInteger i = [allItems indexOfObject:self.tabBar.selectedItem];
        if (i != NSNotFound) {
            [self showViewController:[viewControllers objectAtIndex:i]];
        } else {
            [self showViewController:moreNavigationController];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.appModalHolder.modalViewController) {
        return appDelegate.appModalHolder.canRotate;
    }
    return NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.appModalHolder.modalViewController) {
        [appDelegate.appModalHolder.modalViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.appModalHolder.modalViewController) {
        [appDelegate.appModalHolder.modalViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark getter methods

- (NSArray *)allItems {
	return allItems;
}

#pragma mark -
#pragma mark UITabBarController-like methods

- (NSArray *)viewControllers {
    return viewControllers;
}

- (void)setViewControllers:(NSArray *)newViewControllers {
    if (newViewControllers != viewControllers) {
        for (UIViewController *vc in viewControllers) {
            [vc.view removeFromSuperview];
        }
        [viewControllers release];
        viewControllers = [newViewControllers copy];
        // reset which tabs are customizable every time the tabs change, in case tabs were added/removed
        [self setCustomizableViewControllers:viewControllers];
        
        // recreate tabs
        [self updateTabBarItems];
        
        for (UIViewController *vc in viewControllers) {
            [limboView addSubview:vc.view];
        }
    }
}

- (NSArray *)customizableViewControllers {
    return customizableViewControllers;
}

- (void)setCustomizableViewControllers:(NSArray *)newCustomizableViewControllers {
    if (newCustomizableViewControllers != customizableViewControllers) {
        [customizableViewControllers release];
        customizableViewControllers = [newCustomizableViewControllers copy];
    }
}

- (void)setActiveItem:(UITabBarItem *)item {
    if (item != activeItem) {
        [activeItem release];
        activeItem = [item retain];
        if ([delegate respondsToSelector:@selector(tabBarController:didShowItem:)]) {
            [delegate tabBarController:self didShowItem:item];
        }
    }
}

- (void)updateTabBarItems {
    [allItems release];
    NSMutableArray *newTabBarItems = [NSMutableArray array];
    NSInteger i = 0;
    // create a new UITabBarItem for each view controller in viewControllers
    for (UIViewController *vc in viewControllers) {
        UITabBarItem *anItem = vc.tabBarItem;
        [newTabBarItems addObject:anItem];
        i++;
    }
    allItems = [newTabBarItems copy];
    
    // put the first 5 in the tab bar (or 4 + More if more than 5)
    if ([newTabBarItems count] <= TAB_COUNT + 1) {
        theTabBar.items = [[allItems copy] autorelease];
    } else {
        theTabBar.items = [[allItems subarrayWithRange:NSMakeRange(0, TAB_COUNT)] arrayByAddingObject:moreNavigationController.tabBarItem];
    }
}

- (void)showViewController:(UIViewController *)viewController {
    // if this isn't already the visible view controller
    if (viewController && viewController != selectedViewController) {
        if (selectedViewController) {
            [selectedViewController viewWillDisappear:NO];
            [selectedViewController.view removeFromSuperview];
            [limboView addSubview:selectedViewController.view];
            [selectedViewController viewDidDisappear:NO];
        }
        
        viewController.view.frame = containingView.frame;
        [viewController viewWillAppear:NO];
        [viewController.view removeFromSuperview];
        [containingView addSubview:viewController.view];
        [viewController viewDidAppear:NO];
        self.selectedViewController = viewController;
    }
}

- (void)customizeTabs {
    NSMutableArray *customizableTabs = [NSMutableArray array];

    for (UIViewController *vc in customizableViewControllers) {
        [customizableTabs addObject:vc.tabBarItem];
    }
    
    [theTabBar beginCustomizingItems:customizableTabs];
}

- (void)showItem:(UITabBarItem *)item {
    NSUInteger i = [self.tabBar.items indexOfObject:item];
    
    // if the item is not in the more list, simply activate it
    if (i != NSNotFound) {
        self.tabBar.selectedItem = item;
        [self displayItem:item immediate:YES];
        // displayItem sets activeItem to item as a side effect
    }
    else {
        UITabBarItem *moreItem = moreNavigationController.tabBarItem;
        self.tabBar.selectedItem = moreItem;
        [self displayItem:moreItem immediate:YES];
        self.activeItem = item;
        [self showItemOnMoreList:item animated:NO];
        // manually call this delegate method because the controller doesn't know we forced it to push
        [self navigationController:moreNavigationController didShowViewController:moreNavigationController.visibleViewController animated:NO];
    }
}

// displays one of the visible tab bar items (e.g. not something hidden under More)
- (void)displayItem:(UITabBarItem *)item immediate:(BOOL)immediate {
    UIViewController *vc = nil;
    for (vc in viewControllers) {
        if (vc.tabBarItem == item) {
            break;
        }
    }
    if (vc) {
        // Don't waste time if this is already the active tab
        if ([vc isKindOfClass:[UINavigationController class]] && vc != selectedViewController) {
            // This little dance is required in case this tab was last used 
            // under the More tab, meaning its navigation stack was stolen
            // by the moreListController. Without unsetting and resetting the 
            // tab's nav controller's viewControllers, the tab's navbar will
            // have no title and may not even allow the pushing of other 
            // viewcontrollers onto its stack.
            UINavigationController *navC = (UINavigationController *)vc;
            NSArray *otherNavStack = [navC.viewControllers retain];
            [navC setViewControllers:nil animated:NO];
            [navC setViewControllers:otherNavStack animated:NO];
            [otherNavStack release];
        }
        [self showViewController:vc];
    } else {
        // any tab not among viewControllers must be the More tab.
        // whenever the More tab is tapped, it should show its root list of remaining modules
        if (selectedViewController == moreNavigationController) {
            // slide if More tab's already active
            [moreNavigationController popToRootViewControllerAnimated:!immediate];
        } else {
            // be there already if More tab's not active yet
            [moreNavigationController popToRootViewControllerAnimated:NO];
            [self showViewController:moreNavigationController];
        }
    }
    // update old module's navstack
    if (self.activeTabNavStack) {
        NSInteger i = [allItems indexOfObject:self.activeItem];
        UINavigationController *navC = [viewControllers objectAtIndex:i];
        [navC setViewControllers:nil animated:NO];
        [navC setViewControllers:activeTabNavStack animated:NO];
        self.activeTabNavStack = nil;
    }
    self.activeItem = item;    
}

- (void)updateCustomizableViewControllers:(NSArray *)modules {
    NSMutableArray *customizableVCs = [[self.customizableViewControllers mutableCopy] autorelease];
    for (MITModule *aModule in modules) {
        if (!aModule.isMovableTab) {
            [customizableVCs removeObject:aModule.tabNavController];
        }
    }
    [self setCustomizableViewControllers:customizableVCs];
}

#pragma mark -
#pragma mark Tab bar delegation

- (void)tabBar:(UITabBar *)tabBar willEndCustomizingItems:(NSArray *)items changed:(BOOL)changed {
    if (changed && tabBar == self.tabBar) {
        // iterate through items, finding them in a mutable copy of tabBarItems
        NSMutableArray *oldVCs = [viewControllers mutableCopy];
        NSMutableArray *oldCustomizableVCs = [customizableViewControllers mutableCopy];
        NSMutableArray *newVCs = [NSMutableArray array];
        NSMutableArray *newCustomizableVCs = [NSMutableArray array];
        NSInteger i = 0;
        for (UITabBarItem *anItem in items) {
            i = [allItems indexOfObject:anItem]; // i == NSNotFound implies More tab
            if (i != NSNotFound) {
                UIViewController *vc = [viewControllers objectAtIndex:i];
                [newVCs addObject:vc];
                [oldVCs removeObject:vc];
                [newCustomizableVCs addObject:vc];
                [oldCustomizableVCs removeObject:vc];
            }
        }
        // anything left must be non-customizable and goes at the end
        [newVCs addObjectsFromArray:oldVCs];
        [oldVCs release];
        [newCustomizableVCs addObjectsFromArray:oldCustomizableVCs];
        [oldCustomizableVCs release];
        [self setViewControllers:newVCs]; // regenerates tabBarItems as a side-effect
        [self setCustomizableViewControllers:newCustomizableVCs];
    }
    
    [moreListController.tableView reloadData];
}

- (void)tabBar:(UITabBar *)tabBar didEndCustomizingItems:(NSArray *)items changed:(BOOL)changed {
    // notify delegate in case it wants to save the new order to disk
    if ([delegate respondsToSelector:@selector(tabBarController:didEndCustomizingViewControllers:changed:)]) {
        [delegate tabBarController:self didEndCustomizingViewControllers:viewControllers changed:changed];
    }
	
	// the more tab bar item value may need to be updated
	if(changed) {
		[MITUnreadNotifications updateUI];
	}
}

// only called on a physical tap
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    [self displayItem:item immediate:NO];
}

- (void)didSelectViewController:(UIViewController *)viewController {
    if ([delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
        [delegate tabBarController:self didSelectViewController:viewController];
    }
}

#pragma mark -
#pragma mark More navigation controller delegation

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    // See -tableView:didSelectRowAtIndexPath:indexPath below for the reason 
    // for this code.
    if (pendingNavigationStack) {
        [moreNavigationController setViewControllers:pendingNavigationStack animated:NO];
        [pendingNavigationStack release];
        pendingNavigationStack = nil;
    }
    
    NSArray *moreVCs = moreNavigationController.viewControllers;
    UIViewController *rootVC = [moreVCs objectAtIndex:0];
    
    if (viewController == rootVC) {
        // We've popped all the way back to the more list, 
        // so update old module's navstack
        if (self.activeTabNavStack) {
            NSInteger i = [allItems indexOfObject:self.activeItem];
            UINavigationController *navC = [viewControllers objectAtIndex:i];
            [navC setViewControllers:nil animated:NO];
            [navC setViewControllers:activeTabNavStack animated:NO];
            self.activeTabNavStack = nil;
        }
        self.activeItem = moreNavigationController.tabBarItem;
    } else if ([moreVCs count] > 1) {
        // We're still in a module within the more list, 
        // so keep the separate copy of the nav stack in sync.
        self.activeTabNavStack = [moreVCs subarrayWithRange:NSMakeRange(1, [moreVCs count] - 1)];
    }
}

- (void)showItemOnMoreList:(UITabBarItem *)item {
    [self showItemOnMoreList:item animated:YES];
}


- (void)showItemOnMoreList:(UITabBarItem *)item animated:(BOOL)animated {
    // special case the mobile web link, so we don't get any pushing of the navigation controller when opening the URL
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    MITModule *theModule = [appDelegate moduleForTabBarItem:item];
    if ([theModule.tag isEqualToString:MobileWebTag]) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", MITMobileWebGetCurrentServerDomain()]];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
        return;
    }
    
    NSInteger i = [allItems indexOfObject:item];
    UIViewController *vc = [viewControllers objectAtIndex:i];
    NSMutableArray *navStack = [moreNavigationController.viewControllers mutableCopy];
    self.activeItem = vc.tabBarItem;
    // We can't push one UINavigationController onto another, so we copy 
    // over its entire navigation stack instead. But 
    // -[UINavigationController setViewControllers:animated:] is broken
    // in iPhone OS 3.1.2 when called with animated:YES. The nav bar
    // starts drawing buttons incorrectly and swaps actions between them.
    // To get around that bug, we only push in the top view controller of 
    // the stack, then once that is done transitioning in (see 
    // -navigationController:didShowViewController:animated: above),
    // we replace the entire navigation stack in a non-animated (and
    // non-buggy) way.
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navVC = (UINavigationController *)vc;
        [navStack addObjectsFromArray:navVC.viewControllers];
    } else {
        [navStack addObject:vc];
    }
    self.activeTabNavStack = navStack;
    pendingNavigationStack = navStack;
    [moreNavigationController pushViewController:[navStack lastObject] animated:animated];    
}


@end
