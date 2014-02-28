#import "CMModule.h"

#import "CampusMapViewController.h"
#import "MITMapDetailViewController.h"
#import "MITCampusMapViewController.h"
#import "MITModule+Protected.h"
#import "MITMapPlace.h"

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
    self.moduleHomeController = [[MITCampusMapViewController alloc] init];
}

- (MITCampusMapViewController*)campusMapVC
{
    return nil;
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
	
    NSNumber *centerLatNumber = regionDictionary[@"centerLat"];
    NSNumber *centerLongNumber = regionDictionary[@"centerLong"];
    CLLocationDegrees centerLat = 0.0;
    CLLocationDegrees centerLong = 0.0;
	if (centerLatNumber && centerLongNumber) {
        centerLat = [centerLatNumber doubleValue];
        centerLong = [centerLongNumber doubleValue];
	}
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(centerLat, centerLong);

    NSNumber *spanLatNumber = regionDictionary[@"spanLat"];
    NSNumber *spanLongNumber = regionDictionary[@"spanLong"];
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
	} else {
        if ([localPath hasPrefix:@"search"]) {
            MITCampusMapViewController *campusMapController = [[MITCampusMapViewController alloc] init];
            [campusMapController setPendingSearch:query];
            [[MIT_MobileAppDelegate applicationDelegate].rootNavigationController pushViewController:campusMapController animated:YES];
        } else {
            DDLogWarn(@"Ignoring URL request for %@", localPath);
        }
        
        /*
        NSMutableArray *components = [NSMutableArray arrayWithArray:[localPath componentsSeparatedByString:@"/"]];
        NSString *pathRoot = components[0];
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
        
            
                NSMutableArray* searchResultsArr = [NSMutableArray arrayWithCapacity:[searchResultsArray count]];
            
                for (NSDictionary* info in searchResultsArray) {
                    MITMapPlace *mapPlace = [[MITMapPlace alloc] initWithDictionary:info];
                    MITMapSearchResultAnnotation* annotation = [[MITMapSearchResultAnnotation alloc] initWithPlace:mapPlace];
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

            if ([components count] >= 2) {
                // if there is a building number, show callout
                NSString* annotationUniqueID = nil;
                if ([pathRoot isEqualToString:@"list"] && ([components count] > 2)) {
                    annotationUniqueID = components[2];
                } else {
                    annotationUniqueID = components[1];
                }

                
                // look for the selected annotation among the array of annotations
                for (MITMapSearchResultAnnotation* annotation in self.campusMapVC.mapView.annotations) {
                    if([annotation.place.identifier isEqualToString:annotationUniqueID]) {
                        [self.campusMapVC.mapView selectAnnotation:annotation animated:NO withRecenter:NO];
                        currentAnnotation = annotation;
                    }
                }
            }
            
            
            MITMapDetailViewController *detailsVC = nil;
            if ([pathRoot isEqualToString:@"list"]) {
                [self.campusMapVC showListView:YES];
                
                if ([components count]) {
                    [components removeObjectAtIndex:0];
                }
            } else if ([pathRoot isEqualToString:@"detail"]) {
                // push the details page onto the stack for the item selected. 
                detailsVC = [[MITMapDetailViewController alloc] initWithNibName:@"MITMapDetailViewController"
                                                                          bundle:nil];

                detailsVC.place = currentAnnotation.place;
                detailsVC.title = @"Info";
                detailsVC.campusMapVC = self.campusMapVC;
                if ([components count]) {
                    detailsVC.startingTab = [components[2] intValue];
                }

                if([self.campusMapVC.lastSearchText length]) {
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
        }*/
	}
	
	return NO;
}

@end
