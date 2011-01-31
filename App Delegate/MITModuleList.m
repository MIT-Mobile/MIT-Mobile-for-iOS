#import "MITModuleList.h"
#import "NewsModule.h"
#import "ShuttleModule.h"
#import "StellarModule.h"
#import "PeopleModule.h"
#import	"CMModule.h"
#import "EmergencyModule.h"
#import "MobileWebModule.h"
#import "SettingsModule.h"
#import "AboutModule.h"
#import "CalendarModule.h"
#import "ToursModule.h"
#import "AnniversaryModule.h"
#import "MITTabBarController.h"

// #import your module's header here

@implementation MIT_MobileAppDelegate (ModuleListAdditions)
#pragma mark class methods
+ (MITModule *)moduleForTag:(NSString *)aTag {
	MIT_MobileAppDelegate *delegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	return [delegate moduleForTag:aTag];
}

#pragma mark Basics
- (NSMutableArray *)createModules {
    // The order of this array is the default module order
    NSMutableArray *result = [NSMutableArray array];
    
    // add your MITModule subclass here by duplicating this line
    //[result addObject:[[[YourMITModuleSubclass alloc] init] autorelease]];
    [result addObject:[[[NewsModule alloc] init] autorelease]];
    [result addObject:[[[ShuttleModule alloc] init] autorelease]];
	[result addObject:[[[CMModule alloc] init] autorelease]];
	[result addObject:[[[CalendarModule alloc] init] autorelease]];
	[result addObject:[[[StellarModule alloc] init] autorelease]];
	[result addObject:[[[PeopleModule alloc] init] autorelease]];
    [result addObject:[[[ToursModule alloc] init] autorelease]];
    [result addObject:[[[AnniversaryModule alloc] init] autorelease]];
    [result addObject:[[[EmergencyModule alloc] init] autorelease]];
    [result addObject:[[[MobileWebModule alloc] init] autorelease]];
    [result addObject:[[[SettingsModule alloc] init] autorelease]];
    [result addObject:[[[AboutModule alloc] init] autorelease]];
    
    return result;
}

- (MITModule *)moduleForTabBarItem:(UITabBarItem *)item {
    for (MITModule *aModule in self.modules) {
        if ([aModule.tabNavController.tabBarItem isEqual:item]) {
            return aModule;
        }
    }
    return nil;
}
/*
- (MITModule *)moduleForViewController:(UIViewController *)aViewController {
    for (MITModule *aModule in self.modules) {
        if ([aModule.tabNavController isEqual:aViewController]) {
            return aModule;
        }
    }
    return nil;
}
*/
- (MITModule *)moduleForTag:(NSString *)aTag {
    for (MITModule *aModule in self.modules) {
        if ([aModule.tag isEqual:aTag]) {
            return aModule;
        }
    }
    return nil;
}

- (void)showModuleForTag:(NSString *)tag {
    if ([tag isEqualToString:MobileWebTag]) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", MITMobileWebDomainString]];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
        return;
    }
    
    MITModule *module = [self moduleForTag:tag];
    [module loadTabNavController];
    if (navParadigm == MITNavigationParadigmTabBar) {
        // tabbar will set hasLaunchedBegun in -didShowItem:
        [self.tabBarController showItem:module.tabNavController.tabBarItem];
    }
    else {
        if ([self.normalNavController.visibleViewController isKindOfClass:[MITSpringboard class]]) {
			[module.tabNavController popToRootViewControllerAnimated:NO];
            NSArray *viewControllers = [self.normalNavController.viewControllers arrayByAddingObjectsFromArray:module.tabNavController.viewControllers];
            [self.normalNavController setViewControllers:viewControllers animated:YES];
        }
        else {
            [self.normalNavController pushViewController:module.tabNavController.visibleViewController animated:YES];
        }
        module.hasLaunchedBegun = YES;
        [module didAppear];
    }
}

#pragma mark Preferences
- (NSArray *)defaultModuleOrder {
    NSMutableArray *moduleNames = [NSMutableArray arrayWithCapacity:[self.modules count]];
    for (MITModule *aModule in self.modules) {
        [moduleNames addObject:aModule.tag];
    }
	return moduleNames;
}

- (void)registerDefaultModuleOrder {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *moduleNames = [self defaultModuleOrder];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          moduleNames, MITModuleTabOrderKey, nil];                          
    // Register defaults -- only has an effect if this is the first time this app has run on the device
    [defaults registerDefaults:dict];
    [defaults synchronize];    
}

- (void)loadSavedModuleOrder {
	// In 3.0, there is no module order customization.
	BOOL wipeSavedOrder = (TRUE);
    NSArray *savedModuleOrder = [[NSUserDefaults standardUserDefaults] objectForKey:MITModuleTabOrderKey];
    NSMutableArray *oldModules = [[self.modules mutableCopy] autorelease];
    NSMutableArray *newModules = [NSMutableArray arrayWithCapacity:[self.modules count]];
	if (wipeSavedOrder) {
		savedModuleOrder = [self defaultModuleOrder];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:MITEventsModuleInSortOrderKey];
	}
    for (NSString *aTag in savedModuleOrder) {
        MITModule *aModule = [self moduleForTag:aTag];
        if (aModule) {
            [oldModules removeObject:aModule];
            [newModules addObject:aModule];
        }
    }
    [newModules addObjectsFromArray:oldModules]; // in case modules have been added
    self.modules = [[newModules copy] autorelease]; // immutable copy
}

- (void)loadActiveModule {
    // Show the module which was visible the last time we quit
    // If that module isn't allowed to be visible at start, ignore it -- the first tab is selected by default.
    NSString *activeModuleTag = [[NSUserDefaults standardUserDefaults] objectForKey:MITActiveModuleKey];
    MITModule *activeModule = [self moduleForTag:activeModuleTag];
    if (activeModule && activeModule.canBecomeDefault) {
        if (navParadigm == MITNavigationParadigmTabBar) {
            self.tabBarController.activeItem = activeModule.tabNavController.tabBarItem;
        } else {
            // TODO: this doesn't make sense in one-dimensional navigation.
            // we should be restoring the entire nav stack.
        }
    }
}

- (void)saveModuleOrder {
    // we don't allow reordering of modules on home screen yet
    if (navParadigm == MITNavigationParadigmTabBar) {
        NSMutableArray *newModules = [NSMutableArray arrayWithCapacity:[self.modules count]];
        NSMutableArray *moduleNames = [NSMutableArray arrayWithCapacity:[self.modules count]]; 
        MITModule *aModule = nil;
        
        for (UITabBarItem *item in self.tabBarController.allItems) {
            aModule = [self moduleForTabBarItem:item];
            if (aModule && ![moduleNames containsObject:aModule.tag]) {
                [newModules addObject:aModule];
                [moduleNames addObject:aModule.tag];
            }
        }
        self.modules = [[newModules copy] autorelease]; // immutable copy
        
        // Save updated order: module list into an array of strings, then save that array to disk
        [[NSUserDefaults standardUserDefaults] setObject:moduleNames forKey:MITModuleTabOrderKey];
        [[NSUserDefaults standardUserDefaults] setObject:[self activeModuleTag] forKey:MITActiveModuleKey];
    }
}

- (void)saveModulesState {
	NSMutableDictionary *modulesSavedState = [NSMutableDictionary dictionary];
    for (MITModule *aModule in self.modules) {
		if (aModule.currentPath && aModule.currentQuery) {
			[modulesSavedState setObject:[NSDictionary dictionaryWithObjectsAndKeys:aModule.currentPath, @"path", aModule.currentQuery, @"query", nil] forKey:aModule.tag];
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:modulesSavedState forKey:MITModulesSavedStateKey];
}
		
- (NSString *) activeModuleTag {
    if (navParadigm == MITNavigationParadigmTabBar) {
        return [[self moduleForTabBarItem:self.tabBarController.activeItem] tag];
    } else {
		return [moduleStack lastObject];
    }
}

@end
