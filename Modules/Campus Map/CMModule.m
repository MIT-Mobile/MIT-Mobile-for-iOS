#import "CMModule.h"
#import "CampusMapViewController.h"
//#import "MITMapViewController.h"
#import "MITMapDetailViewController.h"
#import "MITMapSearchResultAnnotation.h"

@implementation CMModule
@synthesize campusMapVC = _campusMapVC;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = CampusMapTag;
        self.shortName = @"Map";
        self.longName = @"Campus Map";
        self.iconName = @"map";
        
        self.campusMapVC.title = self.longName;
       
		//self.campusMapVC = [[[CampusMapViewController alloc] init] autorelease];
		//self.campusMapVC.title = @"Campus Map";
		//self.campusMapVC.campusMapModule = self;
		
        //[self.tabNavController setViewControllers:[NSArray arrayWithObject:self.campusMapVC]];
    }
    return self;
}

- (UIViewController *)moduleHomeController {
    if (!self.campusMapVC) {
        self.campusMapVC = [[[CampusMapViewController alloc] init] autorelease];
        self.campusMapVC.campusMapModule = self;
    }
    return self.campusMapVC;
}

-(void) dealloc
{
	self.campusMapVC = nil;
	
	[super dealloc];
}

- (void)applicationDidEnterBackground {
    if (self.tabNavController.visibleViewController == self.campusMapVC) {
        [self.campusMapVC viewWillDisappear:NO];
    }
}

- (void)applicationWillEnterForeground {
    if (self.tabNavController.visibleViewController == self.campusMapVC) {
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
	MKCoordinateRegion region;
	
	CLLocationCoordinate2D centerCoord;
	if(nil != [regionDictionary objectForKey:@"centerLat"] && nil != [regionDictionary objectForKey:@"centerLong"])
	{
		centerCoord.latitude = [[regionDictionary objectForKey:@"centerLat"] doubleValue];
		centerCoord.longitude = [[regionDictionary objectForKey:@"centerLong"] doubleValue];
	}
	region.center = centerCoord;
	
	MKCoordinateSpan span;
	if(nil != [regionDictionary objectForKey:@"spanLat"] && nil != [regionDictionary objectForKey:@"spanLong"])
	{
		span.latitudeDelta = [[regionDictionary objectForKey:@"spanLat"] doubleValue];
		span.longitudeDelta = [[regionDictionary objectForKey:@"spanLong"] doubleValue];
		region.span = span;
	}
	
	// force the map view to load
	self.campusMapVC.view;
    
    if ([(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] usesTabBar]) {
        // make sure the campus map is the root view controller
        [self popToRootViewController];
    }
	
	if (localPath.length==0) {
		if (regionDictionary != nil) {
			// if the only user preset is the map's region, set it.	
			self.campusMapVC.mapView.region = region;
		}
		return YES;
	}
	
	NSMutableArray *components = [NSMutableArray arrayWithArray:[localPath componentsSeparatedByString:@"/"]];
	NSString *pathRoot = [components objectAtIndex:0];
	
	if ([pathRoot isEqualToString:@"search"] || [pathRoot isEqualToString:@"list"] || [pathRoot isEqualToString:@"detail"]) {
		
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
            [self becomeActiveTab];
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
		
		
		if ([pathRoot isEqualToString:@"list"]) {
			[self.campusMapVC showListView:YES];
			
			if (components.count > 1) {
				pathRoot = [components objectAtIndex:1];
				[components removeObjectAtIndex:0];
			}
		}
		else if ([pathRoot isEqualToString:@"detail"]) {	
			// push the details page onto the stack for the item selected. 
			MITMapDetailViewController* detailsVC = [[[MITMapDetailViewController alloc] initWithNibName:@"MITMapDetailViewController"
																								  bundle:nil] autorelease];
			
			detailsVC.annotation = currentAnnotation;
			detailsVC.title = @"Info";
			detailsVC.campusMapVC = self.campusMapVC;
			if (components.count > 2)
				detailsVC.startingTab = [[components objectAtIndex:2] intValue];
			
//			if (self.campusMapVC.selectedCategory) {
//				detailsVC.queryText = currentAnnotation.name;
//			} else 
			if(self.campusMapVC.lastSearchText != nil && self.campusMapVC.lastSearchText.length > 0) {
				detailsVC.queryText = self.campusMapVC.lastSearchText;
			}
						
			[self.campusMapVC.navigationController pushViewController:detailsVC animated:YES];				
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
        
        // make sure the map is the active bar
        [self becomeActiveTab];
		
		return YES;
	}
	
	return NO;
}

@end
