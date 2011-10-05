#import "MIT150ViewController.h"
#import "FeatureSection.h"
#import "FeatureLink.h"
#import "UIKit+MITAdditions.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"
#import "WelcomeViewController.h"
#import "CorridorListViewController.h"
#import "MIT150Button.h"
#import "MultiControlCell.h"
#import "BorderedTableViewCell.h"
#import "MIT_MobileAppDelegate.h"


#define DEFAULT_BUTTON_HEIGHT 100
#define DEFAULT_BUTTON_WIDTH 80

static NSString * const kMIT150LastUpdated = @"MIT150LastUpdated";

@interface MIT150ViewController (Private)

- (NSArray *)allFeatureSections;
- (FeatureSection *)featureSectionForSection:(NSInteger)section;
- (FeatureLink *)featureLinkForIndexPath:(NSIndexPath *)indexPath;

- (void)rebuildFeaturedButtons;
- (void)requestFeatures;

@end


@implementation MIT150ViewController

@synthesize featuredButtonGroups, buttonMargins;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"MIT150";
    self.view.backgroundColor = [UIColor whiteColor];

    self.buttonMargins = CGSizeMake(8.0, 8.0);
    
    NSInteger lastUpdated = [[[NSUserDefaults standardUserDefaults] objectForKey:kMIT150LastUpdated] integerValue];
    if (!lastUpdated || [[NSDate date] timeIntervalSince1970] - lastUpdated > 60) {
        [self requestFeatures];
    } else {
        [self rebuildFeaturedButtons];
    }
}

- (void)requestFeatures {
    MITMobileWebAPI *api = [MITMobileWebAPI jsonLoadedDelegate:self];
    [api requestObjectFromModule:@"features" command:@"list" parameters:nil];
}

- (void)rebuildFeaturedButtons {
    NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES] autorelease];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title = 'features'"];
    FeatureSection *topSection = [[CoreDataManager objectsForEntity:@"FeatureSection" matchingPredicate:predicate] lastObject];
    NSArray *featureLinks = [topSection.links sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    
    NSMutableArray *buttonGroups = [NSMutableArray array];
    NSMutableArray *buttons = [NSMutableArray array];
    
    DLog(@"MIT150 featured links: %@", featureLinks);
    
    CGFloat width, remainingWidth;
    width = remainingWidth = self.view.frame.size.width - (self.buttonMargins.width * 2.0);
    __block CGFloat spacing, height = 0;
    NSInteger row = 0;
    
    void (^finalizeButtonGroup)(NSArray *, BOOL) = ^(NSArray *buttons, BOOL isFirstRow) {
        NSInteger count = [buttons count];
        height += (isFirstRow) ? (2.0 * self.buttonMargins.height) : self.buttonMargins.height;
        spacing = (count > 1) ? remainingWidth / [buttons count] : 0;
        [buttonGroups addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 buttons, @"buttons", 
                                 [NSNumber numberWithFloat:spacing], @"spacing",
                                 [NSNumber numberWithFloat:height], @"height",
                                 nil]];
    };

    for (FeatureLink *featureLink in featureLinks) {
        // prep rows for featured data
        if (remainingWidth < featureLink.size.width) {
            finalizeButtonGroup(buttons, (row == 0));
            buttons = [NSMutableArray array];
            row += 1;
            remainingWidth = width;
            height = 0;
            spacing = 0;
        }

        remainingWidth -= featureLink.size.width;
        height = MAX(height, featureLink.size.height);
        
        MIT150Button *aButton = [[[MIT150Button alloc] init] autorelease];
        aButton.featureLink = featureLink;
        
        [buttons addObject:aButton];
    }
    // fill in last row
    finalizeButtonGroup(buttons, (row == 0));

    self.featuredButtonGroups = buttonGroups;
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Internal URL handlers

- (void)showWelcome {
	WelcomeViewController *welcomeVC = [[WelcomeViewController alloc] initWithNibName:nil bundle:nil];
	[[MITAppDelegate() rootNavigationController] pushViewController:welcomeVC
                                                           animated:YES];
	[welcomeVC release];
}

- (void)showCorridor {
	CorridorListViewController *corridorVC = [[CorridorListViewController alloc] initWithNibName:nil bundle:nil];
	[[MITAppDelegate() rootNavigationController] pushViewController:corridorVC
                                                           animated:YES];
	[corridorVC release];
}

#pragma mark -
#pragma mark Table view data source

- (NSArray *)allFeatureSections {
	NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"ordinality" ascending:YES] autorelease];
	NSArray *featureSections = [CoreDataManager objectsForEntity:@"FeatureSection" 
											   matchingPredicate:nil 
												 sortDescriptors:[NSArray arrayWithObject:sort]];
	return featureSections;
}

- (FeatureSection *)featureSectionForSection:(NSInteger)section {
	NSArray *featureSections = [self allFeatureSections];
	FeatureSection *aFeatureSection = nil;
	
	if ([featureSections count] >= section) {
		aFeatureSection = [featureSections objectAtIndex:section];
	}
	return aFeatureSection;
}

- (FeatureLink *)featureLinkForIndexPath:(NSIndexPath *)indexPath {
	FeatureSection *aFeatureSection = [self featureSectionForSection:indexPath.section];
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES] autorelease];
	NSArray *links = [aFeatureSection.links sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	FeatureLink *link = [links objectAtIndex:indexPath.row];
	
	return link;	
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self allFeatureSections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger sectionCount = 0;

    if (section == 0) {
        sectionCount = [self.featuredButtonGroups count];
    } else {
        FeatureSection *aFeatureSection = [self featureSectionForSection:section];
        if (aFeatureSection) {
            sectionCount = [aFeatureSection.links count];
        }
    }
	
    return sectionCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = self.tableView.rowHeight;
    if (indexPath.section == 0) {
        CGFloat cachedHeight = [[[self.featuredButtonGroups objectAtIndex:indexPath.row] objectForKey:@"height"] floatValue];
        if (cachedHeight <= 0) {
            WLog(@"cached height for %@ was %f", indexPath, cachedHeight);
        }
        height = cachedHeight;
    }
    return height;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *featuredCellIdentifier = @"featuredCell";
    static NSString *linkCellIdentifier = @"linkCell";
    
    UITableViewCell *cell = nil;
    
    /*
     * In order to have a mix of separator / no separator sections in this 
     * tableview, we need to turn separators off entirely and then bring 
     * them back through a custom UITableViewCell
     */
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // No separator for buttons in top section
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:featuredCellIdentifier];
        if (cell == nil) {
            cell = [[[MultiControlCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:featuredCellIdentifier] autorelease];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contentView.backgroundColor = [UIColor whiteColor];
        NSDictionary *buttonGroup = [self.featuredButtonGroups objectAtIndex:indexPath.row];
        ((MultiControlCell *)cell).position = indexPath.row;
        ((MultiControlCell *)cell).margins = self.buttonMargins;
        ((MultiControlCell *)cell).horizontalSpacing = [[buttonGroup objectForKey:@"spacing"] floatValue];
        ((MultiControlCell *)cell).controls = [buttonGroup objectForKey:@"buttons"];
    // Separator via BorderedTableViewCell for other sections
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:linkCellIdentifier];
        if (cell == nil) {
            cell = [[[BorderedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:linkCellIdentifier] autorelease];
        }
        // use default border color
        ((BorderedTableViewCell *)cell).borderColor = self.tableView.separatorColor;
        
        FeatureLink *link = [self featureLinkForIndexPath:indexPath];
        cell.textLabel.text = link.title;
        NSURL *linkURL = [NSURL URLWithString:link.url];
        if ([[linkURL scheme] isEqualToString:@"mitmobile"]) {
            if ([[linkURL host] isEqualToString:@"calendar"]) {
                cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewCalendar];
            } else {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.accessoryView = nil;
            }
        } else {
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
        }
    }
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = nil;
    if (section != 0) {
        FeatureSection *aFeatureSection = [self featureSectionForSection:section];
        header = [UITableView ungroupedSectionHeaderWithTitle:aFeatureSection.title];
    }
    return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	FeatureLink *link = [self featureLinkForIndexPath:indexPath];
	
	NSURL *externalURL = [NSURL URLWithString:link.url];

	DLog(@"Opening external URL: %@", externalURL);
	
    if ([[UIApplication sharedApplication] canOpenURL:externalURL]) {
        [[UIApplication sharedApplication] openURL:externalURL];
    }
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark -
#pragma mark JSONLoadedDelegate

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject {
    if ([JSONObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *JSONDict = (NSDictionary *)JSONObject;
        NSInteger lastModified = [[JSONDict objectForKey:@"last-modified"] integerValue];
        NSInteger lastUpdated = [[[NSUserDefaults standardUserDefaults] objectForKey:kMIT150LastUpdated] integerValue];
        if (lastModified > lastUpdated) {
			// Delete old content
			NSArray *featureSections = [CoreDataManager objectsForEntity:@"FeatureSection" matchingPredicate:nil];
            NSArray *featureLinks = [CoreDataManager objectsForEntity:@"FeatureLink" matchingPredicate:nil];
			[CoreDataManager deleteObjects:featureSections];
            [CoreDataManager deleteObjects:featureLinks];
			
			
			// __block required so that aSection can change between uses of the createFeatureLinkAndSetSection block
			__block FeatureSection *aSection = [FeatureSection featureSectionWithTitle:@"features"];
			
			void (^createFeatureLinkAndSetSection)(id, NSUInteger, BOOL *) = ^(id obj, NSUInteger idx, BOOL *stop) {
				NSDictionary *aDict = nil;
				if ([obj isKindOfClass:[NSDictionary class]]) {
					aDict = obj;
					FeatureLink *aFeatureLink = [FeatureLink featureLinkWithDictionary:aDict];
					aFeatureLink.featureSection = aSection;
				}
			};
			
			// first create the main features
            NSArray *features = [JSONDict objectForKey:@"features"];
			[features enumerateObjectsUsingBlock:createFeatureLinkAndSetSection];
			
			// then create the other links
			aSection = nil;
			NSArray *otherSections = [JSONDict objectForKey:@"more-features"];
			
			for (id obj in otherSections) {
				if ([obj isKindOfClass:[NSDictionary class]]) {
					NSDictionary *sectionDict = obj;
					NSString *sectionTitle = [sectionDict objectForKey:@"section-title"];
					aSection = [FeatureSection featureSectionWithTitle:sectionTitle];
					NSArray *sectionLinks = [sectionDict objectForKey:@"items"];
					[sectionLinks enumerateObjectsUsingBlock:createFeatureLinkAndSetSection];
				}
			};
			
            [CoreDataManager saveData];
			// TODO: Move lastModified from NSUserDefaults into CoreData to simplify code
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:lastModified] forKey:kMIT150LastUpdated];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    [self rebuildFeaturedButtons];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error {
    return YES;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
