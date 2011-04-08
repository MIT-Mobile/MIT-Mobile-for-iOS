#import "MIT150ViewController.h"
#import "FeatureSection.h"
#import "FeatureLink.h"
#import "UIKit+MITAdditions.h"
#import "CoreDataManager.h"
#import <QuartzCore/QuartzCore.h>
#import "Foundation+MITAdditions.h"
#import "WelcomeViewController.h"
#import "CorridorListViewController.h"

#define DEFAULT_BUTTON_HEIGHT 100
#define DEFAULT_BUTTON_WIDTH 80

static NSString * const kMIT150LastUpdated = @"MIT150LastUpdated";

@interface MIT150ViewController (Private)

- (NSArray *)allFeatureSections;
- (FeatureSection *)featureSectionForSection:(NSInteger)section;
- (FeatureLink *)featureLinkForIndexPath:(NSIndexPath *)indexPath;

- (void)setupTableHeader;
- (void)requestFeatures;

@end


@implementation MIT150ViewController

#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"MIT150";
    self.view.backgroundColor = [UIColor whiteColor];

    NSInteger lastUpdated = [[[NSUserDefaults standardUserDefaults] objectForKey:kMIT150LastUpdated] integerValue];
    if (!lastUpdated || [[NSDate date] timeIntervalSince1970] - lastUpdated > 60) {
        [self requestFeatures];
    } else {
        [self setupTableHeader];
    }
}

- (void)requestFeatures {
    MITMobileWebAPI *api = [MITMobileWebAPI jsonLoadedDelegate:self];
    [api requestObjectFromModule:@"features" command:@"list" parameters:nil];
}

// TODO: replace Icon Grid in table header with custom tableviewcells similar to how photo albums work

- (void)setupTableHeader {
    if (!self.tableView.tableHeaderView) {
        NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES] autorelease];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title = 'features'"];
		FeatureSection *topSection = [[CoreDataManager objectsForEntity:@"FeatureSection" matchingPredicate:predicate] lastObject];
        NSArray *featureLinks = [topSection.links sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
		
        NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:featureLinks.count];
        for (FeatureLink *featureLink in featureLinks) {
            MIT150Button *aButton = [[[MIT150Button alloc] init] autorelease];
            aButton.featureLink = featureLink;
            [buttons addObject:aButton];
        }
        
        CGRect frame = self.tableView.frame;
        frame.size.height = DEFAULT_BUTTON_HEIGHT + 20;
        IconGrid *grid = [[[IconGrid alloc] initWithFrame:frame] autorelease];
		grid.backgroundColor = [UIColor whiteColor];
		grid.delegate = self;
//        grid.padding = GridPaddingMake(8, 8, 8, 8);
//        grid.spacing = GridSpacingMake(8, 8);
        grid.icons = buttons;
        self.tableView.tableHeaderView = grid;
    }
}

#pragma mark -
#pragma mark IconGrid delegation
- (void)iconGridFrameDidChange:(IconGrid *)iconGrid {
	self.tableView.tableHeaderView = iconGrid;
}

- (void)showWelcome {
	WelcomeViewController *welcomeVC = [[WelcomeViewController alloc] initWithNibName:nil bundle:nil];
	[self.navigationController pushViewController:welcomeVC animated:YES];
	[welcomeVC release];
}

- (void)showCorridor {
	CorridorListViewController *corridorVC = [[CorridorListViewController alloc] initWithNibName:nil bundle:nil];
	[self.navigationController pushViewController:corridorVC animated:YES];
	[corridorVC release];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
	
	section += 1; // to skip the missing tableview section content used by the featured buttons at top
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
	NSArray *featureSections = [self allFeatureSections];
    // Return the number of sections.
	NSInteger count = [featureSections count] - 1; // minus one for featured area at top
    return (count > 0) ? count : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger sectionCount = 0;

	FeatureSection *aFeatureSection = [self featureSectionForSection:section];
	if (aFeatureSection) {
		sectionCount = [aFeatureSection.links count];
	}
	
    return sectionCount;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
	FeatureLink *link = [self featureLinkForIndexPath:indexPath];
	
	cell.textLabel.text = link.title;
	cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	FeatureSection *aFeatureSection = [self featureSectionForSection:section];
    return [UITableView ungroupedSectionHeaderWithTitle:aFeatureSection.title];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	FeatureLink *link = [self featureLinkForIndexPath:indexPath];
	
	NSURL *externalURL = [NSURL URLWithString:link.url];

	NSLog(@"Opening external URL: %@", externalURL);
	
    if ([[UIApplication sharedApplication] canOpenURL:externalURL]) {
        [[UIApplication sharedApplication] openURL:externalURL];
    }
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

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
    
    [self setupTableHeader];
	[self.tableView reloadData];
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

@implementation MIT150Button

- (FeatureLink *)featureLink {
    return _featureLink;
}

- (void)setFeatureLink:(FeatureLink *)featureLink {
    [_featureLink release];
    _featureLink = [featureLink retain];
    
    CGRect frame = self.frame;
    
    if (_featureLink.photo) {
        // wasteful way to get image size
        UIImage *image = [UIImage imageWithData:_featureLink.photo];
        frame.size.width = image.size.width;
        frame.size.height = image.size.height;
    } else {
        frame.size.width = DEFAULT_BUTTON_WIDTH;
        frame.size.height = DEFAULT_BUTTON_HEIGHT;
    }
    self.frame = frame;
    [self addTarget:self action:@selector(wasTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 5.0;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.frame;
    frame.origin = CGPointZero;
    
    // background
    MITThumbnailView *thumbnail = (MITThumbnailView *)[self viewWithTag:8001];
    if (!thumbnail) {
        thumbnail = [[[MITThumbnailView alloc] initWithFrame:frame] autorelease];
        thumbnail.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        thumbnail.delegate = self;
        thumbnail.tag = 8001;
        thumbnail.userInteractionEnabled = NO;
        [self addSubview:thumbnail];
    } else {
        thumbnail.frame = frame;
    }
    if (self.featureLink.photo) {
        thumbnail.imageData = self.featureLink.photo;
    } else {
        thumbnail.imageURL = self.featureLink.photoURL;
    }
    [thumbnail loadImage];
    
    UIColor *tintColor = [UIColor colorWithHexString:self.featureLink.tintColor];
	
    if (self.featureLink.title && !self.featureLink.subtitle) {
        // title
        UIFont *font = [UIFont boldSystemFontOfSize:13];
        CGSize size = [self.featureLink.title sizeWithFont:font];
        frame = CGRectMake(10, 4, self.frame.size.width - 20, size.height);
        
        UILabel *titleLabel = (UILabel *)[self viewWithTag:8003];
        if (!titleLabel) {
            titleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.font = font;
            titleLabel.tag = 8003;
            titleLabel.userInteractionEnabled = NO;
            titleLabel.text = self.featureLink.title;
            [self addSubview:titleLabel];
        } else {
            titleLabel.frame = frame;
        }
        
        // disclosure
        CGRect triangleFrame = CGRectMake(titleLabel.frame.origin.x + size.width, titleLabel.frame.origin.y, 10, titleLabel.frame.size.height);
        UILabel *triangleLabel = (UILabel *)[self viewWithTag:8005];
        if (!triangleLabel) {
            triangleLabel = [[[UILabel alloc] initWithFrame:triangleFrame] autorelease];
            triangleLabel.textColor = tintColor;
            triangleLabel.font = [UIFont systemFontOfSize:10];
            triangleLabel.text = @"\u25b6";
            triangleLabel.backgroundColor = [UIColor clearColor];
            triangleLabel.tag = 8005;
            [self addSubview:triangleLabel];
        } else {
            triangleLabel.frame = triangleFrame;
        }
        
    } else if (self.featureLink.subtitle) {
        
        // overlay
        frame.origin.y = round(self.frame.size.height * 0.6);
        frame.size.height = round(self.frame.size.height * 0.4);
        
        UIView *overlay = [self viewWithTag:8002];
        if (!overlay) {
            CGFloat * colorComps = (CGFloat *)CGColorGetComponents([tintColor CGColor]);
            
            UIView *overlay = [[UIView alloc] initWithFrame:frame];
            overlay.userInteractionEnabled = NO;
            overlay.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            overlay.backgroundColor = [UIColor colorWithRed:colorComps[0] * 0.3
                                                      green:colorComps[1] * 0.3
                                                       blue:colorComps[2] * 0.3
                                                      alpha:0.6];
            overlay.tag = 8002;
            [self addSubview:overlay];
        }
        
        // title
        frame.origin.x += 10;
        frame.origin.y += 8;
        frame.size.width -= 20;
        
        UIFont *font = [UIFont fontWithName:@"Georgia-Italic" size:14];
        CGSize size = [self.featureLink.title sizeWithFont:font];
        frame.size.height = size.height;
        
        UILabel *titleLabel = (UILabel *)[self viewWithTag:8003];
        if (!titleLabel) {
            titleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = tintColor;
            titleLabel.font = font;
            titleLabel.tag = 8003;
            titleLabel.userInteractionEnabled = NO;
            titleLabel.text = self.featureLink.title;
            [self addSubview:titleLabel];
        } else {
            titleLabel.frame = frame;
        }
        
        // subtitle
        frame.origin.y += frame.size.height + 0;
        
        font = [UIFont systemFontOfSize:13];
        size = [self.featureLink.subtitle sizeWithFont:font constrainedToSize:CGSizeMake(frame.size.width, 2000)];
        frame.size.height = size.height;
        
        UILabel *subtitleLabel = (UILabel *)[self viewWithTag:8004];
        if (!subtitleLabel) {
            subtitleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            subtitleLabel.backgroundColor = [UIColor clearColor];
            subtitleLabel.textColor = [UIColor whiteColor];
            subtitleLabel.font = font;
            subtitleLabel.lineBreakMode = UILineBreakModeWordWrap;
            subtitleLabel.numberOfLines = 2;
            subtitleLabel.tag = 8004;
            subtitleLabel.userInteractionEnabled = NO;
            subtitleLabel.text = self.featureLink.subtitle;
            [self addSubview:subtitleLabel];
        } else {
            subtitleLabel.frame = frame;
        }
        
        // disclosure
        CGRect labelBounds = [subtitleLabel textRectForBounds:subtitleLabel.bounds limitedToNumberOfLines:1];
        CGFloat originY;
        NSInteger position = [subtitleLabel.text lengthOfLineWithFont:font constrainedToSize:labelBounds.size];
        if (position < subtitleLabel.text.length) {
            NSString *substring = [subtitleLabel.text substringFromIndex:position];
            size = [substring sizeWithFont:font];
            originY = frame.origin.y + size.height;
        } else {
            size = [subtitleLabel.text sizeWithFont:font];
            originY = frame.origin.y;
        }
        CGRect triangleFrame = CGRectMake(subtitleLabel.frame.origin.x + size.width + 1, originY, 10, size.height);
        
        UILabel *triangleLabel = (UILabel *)[self viewWithTag:8005];
        if (!triangleLabel) {
            triangleLabel = [[[UILabel alloc] initWithFrame:triangleFrame] autorelease];
            triangleLabel.textColor = tintColor;
            triangleLabel.font = [UIFont systemFontOfSize:10];
            triangleLabel.text = @"\u25b6";
            triangleLabel.backgroundColor = [UIColor clearColor];
            triangleLabel.tag = 8005;
            [self addSubview:triangleLabel];
        } else {
            triangleLabel.frame = triangleFrame;
        }
    }
}

- (void)wasTapped:(id)sender {
    NSURL *url = [NSURL URLWithString:self.featureLink.url];
	NSLog(@"URL = %@", url);
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)dealloc {
    self.featureLink = nil;
    [super dealloc];
}

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    UIImage *image = [UIImage imageWithData:data];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, image.size.width, image.size.height);
    self.featureLink.photo = data;
    [CoreDataManager saveData];
    [self setNeedsLayout];
    [self.superview setNeedsLayout];
}

@end

