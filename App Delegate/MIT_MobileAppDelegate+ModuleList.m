#import "MIT_MobileAppDelegate+ModuleList.h"
#import "NewsModule.h"
#import "ShuttleModule.h"
#import "PeopleModule.h"
#import	"CMModule.h"
#import "EmergencyModule.h"
#import "SettingsModule.h"
#import "AboutModule.h"
#import "CalendarModule.h"
#import "ToursModule.h"
#import "LibrariesModule.h"
#import "MITMobileServerConfiguration.h"
#import "QRReaderModule.h"
#import "FacilitiesModule.h"
#import "LinksModule.h"
#import "DiningModule.h"

// #import your module's header here

@implementation MIT_MobileAppDelegate (ModuleListAdditions)
#pragma mark class methods
+ (MITModule *)moduleForTag:(NSString *)aTag {
	MIT_MobileAppDelegate *delegate = ((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]);
	return [delegate moduleForTag:aTag];
}

#pragma mark Basics
- (void)loadModules {
    // add your MITModule subclass here by adding it to the below
    self.modules = @[[[NewsModule alloc] init],
                     [[ShuttleModule alloc] init],
                     [[CMModule alloc] init],
                     [[CalendarModule alloc] init],
                     [[PeopleModule alloc] init],
                     [[ToursModule alloc] init],
                     [[EmergencyModule alloc] init],
                     [[LibrariesModule alloc] init],
                     [[FacilitiesModule alloc] init],
                     [[DiningModule alloc] init],
                     [[QRReaderModule alloc] init],
                     [[LinksModule alloc] init],
                     [[SettingsModule alloc] init],
                     [[AboutModule alloc] init]];
}

- (MITModule *)moduleForTag:(NSString *)aTag {
    for (MITModule *aModule in self.modules) {
        if ([aModule.tag isEqual:aTag]) {
            return aModule;
        }
    }
    return nil;
}

- (void)showModuleForTag:(NSString *)tag {
    [self.springboardController pushModuleWithTag:tag];
}

#pragma mark Preferences
- (void)saveModulesState {
	NSMutableDictionary *modulesSavedState = [NSMutableDictionary dictionary];
    for (MITModule *aModule in self.modules) {
		if (aModule.currentPath && aModule.currentQuery) {
            NSDictionary *moduleState = @{@"path" : aModule.currentPath,
                                         @"query" : aModule.currentQuery};
            [modulesSavedState setObject:moduleState
                                  forKey:aModule.tag];
		}
	}

	[[NSUserDefaults standardUserDefaults] setObject:modulesSavedState forKey:MITModulesSavedStateKey];
}
@end
