#import "CMModule.h"
#import "CampusMapViewController.h"
#import "MITMapDetailViewController.h"
#import "MITMapSearchResultAnnotation.h"

#import "MITModule+Protected.h"

@implementation CMModule
@dynamic campusMapVC;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = CampusMapTag;
        self.shortName = @"Map";
        self.longName = @"Campus Map";
        self.iconName = @"map";
        
        self.campusMapVC.title = self.longName;
    }
    return self;
}

- (void)loadModuleHomeController
{
    CampusMapViewController *controller = [[[CampusMapViewController alloc] init] autorelease];
    controller.campusMapModule = self;
    
    self.moduleHomeController = controller;
}

- (CampusMapViewController*)campusMapVC
{
    return ((CampusMapViewController*)self.moduleHomeController);
}

-(void) dealloc
{
	[super dealloc];
}

- (void)applicationDidEnterBackground {
    UINavigationController *controller = [MITAppDelegate() rootNavigationController];
    if (controller.visibleViewController == self.campusMapVC) {
        [self.campusMapVC viewWillDisappear:NO];
    }
}

- (void)applicationWillEnterForeground {
    UINavigationController *controller = [MITAppDelegate() rootNavigationController];
    if (controller.visibleViewController == self.campusMapVC) {
        [self.campusMapVC viewWillAppear:NO];
    }
}

/*
 *	the path query syntax can have these syntaxes:
 *		search/<id#>					where id# is optional
 *		detail/<id#>/<tabIndex>			where tabIndex is optional
 *		list/detail/<id#>/<tabIndex>	where detail and tabIndex are optional.
 *	if list is followed by detail etc, then the detail view will load but the back button will lead to the list view.
 */
- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query
{
	// grab the users last location (it could change during the rest of this method)
	NSString* docsFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString* regionFilename = [docsFolder stringByAppendingPathComponent:@"region.plist"];
	NSDictionary* regionDictionary = nil;
	if ([[NSFileManager defaultManager] fileExistsAtPath:regionFilename]) {
		regionDictionary = [NSDictionary dictionaryWithContentsOfFile:regionFilename];
	}
	
    NSNumber *centerLatNumber = [regionDictionary objectForKey:@"centerLat"];
    NSNumber *centerLongNumber = [regionDictionary objectForKey:@"centerLong"];
    CLLocationDegrees centerLat = 0.0;
    CLLocationDegrees centerLong = 0.0;
	if (centerLatNumber && centerLongNumber) {
        centerLat = [centerLatNumber doubleValue];
        centerLong = [centerLongNumber doubleValue];
	}
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(centerLat, centerLong);

    NSNumber *spanLatNumber = [regionDictionary objectForKey:@"spanLat"];
    NSNumber *spanLongNumber = [regionDictionary objectForKey:@"spanLong"];
    CLLocationDegrees spanLat = 0.0;
    CLLocationDegrees spanLong = 0.0;
	if (spanLatNumber && spanLongNumber) {
        spanLat = [spanLatNumber doubleValue];
        spanLong = [spanLongNumber doubleValue];
	}
	MKCoordinateSpan span = MKCoordinateSpanMake(spanLat, spanLong);
    
    MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
	
	if (localPath.length == 0) {
        [[MITAppDelegate() springboardController] pushModuleWithTag:self.tag];
        
		if (regionDictionary != nil) {
			// if the only user preset is the map's region, set it.	
			self.campusMapVC.mapView.region = region;
		}
		return YES;
	}
    else {
        NSMutableArray *components = [NSMutableArray arrayWithArray:[localPath componentsSeparatedByString:@"/"]];
        NSString *pathRoot = [components objectAtIndex:0];
        
        if ([pathRoot isEqualToString:@"search"] || [pathRoot isEqualToString:@"list"] || [pathRoot isEqualToString:@"detail"]) {
            // make sure the map is the active bar
            [[MITAppDelegate() springboardController] pushModuleWithTag:self.tag];
            
            // populate search bar
            self.campusMapVC.searchBar.text = query;
            self.campusMapVC.lastSearchText = query;
            self.campusMapVC.hasSearchResults = YES;
            
            // grab our search results
            NSString* docsFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
            NSString* searchResultsFilename = [docsFolder stringByAppendingPathComponent:@"searchResults.plist"];
            NSArray* searchResultsArray = [NSArray array];
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:CachedMapSearchQueryKey] isEqualToString:query]) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:searchResultsFilename]) {
                    searchResultsArray = [NSArray arrayWithContentsOfFile:searchResultsFilename];
                }
        
            
                NSMutableArray* searchResultsArr = [NSMutableArray arrayWithCapacity:searchResultsArray.count];
            
                for (NSDictionary* info in searchResultsArray)
                {
                    MITMapSearchResultAnnotation* annotation = [[[MITMapSearchResultAnnotation alloc] initWithInfo:info] autorelease];
                    [searchResultsArr addObject:annotation];
                }
                // this will remove old annotations and add the new ones. 
                [self.campusMapVC setSearchResultsWithoutRecentering:searchResultsArr];
            } else {
                // perform the search from the network
                [self.campusMapVC search:query];
                return YES;
            }

            MITMapSearchResultAnnotation* currentAnnotation = nil;

            if (components.count > 1) {
                // if there is a building number, show callout
                NSString* annotationUniqueID = nil;
                if ([pathRoot isEqualToString:@"list"] && components.count > 2) {
                    annotationUniqueID = [components objectAtIndex:2];
                } else {
                    annotationUniqueID = [components objectAtIndex:1];
                }

                
                // look for the selected annotation among the array of annotations
                for (MITMapSearchResultAnnotation* annotation in self.campusMapVC.mapView.annotations) {
                    if([[(MITMapSearchResultAnnotation*)annotation uniqueID] isEqualToString:annotationUniqueID]) {
                        [self.campusMapVC.mapView selectAnnotation:annotation animated:NO withRecenter:NO];
                        currentAnnotation = (MITMapSearchResultAnnotation*)annotation;
                    }
                }
            }
            
            
            MITMapDetailViewController *detailsVC = nil;
            if ([pathRoot isEqualToString:@"list"]) {
                [self.campusMapVC showListView:YES];
                
                if (components.count > 1) {
                    [components removeObjectAtIndex:0];
                }
            }
            else if ([pathRoot isEqualToString:@"detail"])
            {	
                // push the details page onto the stack for the item selected. 
                detailsVC = [[[MITMapDetailViewController alloc] initWithNibName:@"MITMapDetailViewController"
                                                                          bundle:nil] autorelease];
                
                detailsVC.annotation = currentAnnotation;
                detailsVC.title = @"Info";
                detailsVC.campusMapVC = self.campusMapVC;
                if (components.count > 2)
                    detailsVC.startingTab = [[components objectAtIndex:2] intValue];
                
                if(self.campusMapVC.lastSearchText != nil && self.campusMapVC.lastSearchText.length > 0) {
                    detailsVC.queryText = self.campusMapVC.lastSearchText;
                }				
            }
            
            if ([[components lastObject] isEqualToString:@"userLoc"]) {
                self.campusMapVC.mapView.stayCenteredOnUserLocation = YES;
                self.campusMapVC.geoButton.style = UIBarButtonItemStyleDone;
            } else {
                if (regionDictionary != nil) {
                    self.campusMapVC.mapView.region = region;
                }
            }
            // set the url's path and query to these
            [self.campusMapVC.url setPath:localPath query:query];
            [self.campusMapVC.url setAsModulePath];
            
            if (detailsVC) {
                [[MITAppDelegate() rootNavigationController] pushViewController:detailsVC
                                                                       animated:YES];
            }
            
            return YES;
        }
	}
	
	return NO;
}

@end
