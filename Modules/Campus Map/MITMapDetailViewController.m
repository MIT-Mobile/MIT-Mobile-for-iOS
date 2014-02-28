#import <MapKit/MapKit.h>
#import "MITMapDetailViewController.h"
#import "TabViewControl.h"
#import "CampusMapViewController.h"
#import "MITUIConstants.h"
#import "MIT_MobileAppDelegate.h"
#import "MITMapAnnotationView.h"
#import "UIImageView+WebCache.h"
#import "MITMapView.h"
#import "TabViewControl.h"

#import "MITMapModel.h"
#import "MITCoreData.h"

@interface MITMapDetailViewController () <MITMapViewDelegate,TabViewControlDelegate>
// Main View subviews
@property (nonatomic,weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic,weak) IBOutlet UILabel *nameLabel;
@property (nonatomic,weak) IBOutlet UILabel *locationLabel;
@property (nonatomic,weak) IBOutlet UILabel *queryLabel;
@property (nonatomic,weak) IBOutlet UIButton *bookmarkButton;
@property (nonatomic,weak) IBOutlet UIButton *mapViewContainer;
@property (nonatomic,weak) IBOutlet MITMapView *mapView; // Subview of mapViewContainer
@property (nonatomic,weak) IBOutlet UIView *tabViewContainer;
@property (nonatomic,weak) IBOutlet TabViewControl *tabViewControl; // Subview of tabViewContainer

@property (nonatomic,strong) IBOutlet UIView *buildingView;
@property (nonatomic,weak) IBOutlet UIImageView *buildingImageView;
@property (nonatomic,weak) IBOutlet UILabel *buildingImageDescriptionLabel;
@property (nonatomic,weak) IBOutlet UIView *loadingImageView;

@property (nonatomic,strong) IBOutlet UIView *loadingResultView;
@property (nonatomic,strong) IBOutlet UIView *whatsHereView;

@property (strong) NSMutableArray *tabViews;
@property CGFloat tabViewContainerMinHeight;
// load the content of the current annotation into the view.
- (void)loadAnnotationContent;
@end


@implementation MITMapDetailViewController
@synthesize managedObjectContext = _managedObjectContext;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {

	}
	return self;
}

- (instancetype)initWithPlace:(MITMapPlace*)mapPlace
{
    self = [super init];
    if (self) {
        _place = mapPlace;
    }

    return self;
}

- (void)dealloc 
{
    [self.buildingImageView cancelCurrentImageLoad];
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor mit_backgroundColor];
	
	self.tabViews = [[NSMutableArray alloc] init];
	
	// check if this item is already bookmarked
	if (self.place.bookmark) {
		[self.bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on"]
                             forState:UIControlStateNormal];
		[self.bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on_pressed"]
                             forState:UIControlStateHighlighted];
	}

	
	self.mapView.delegate = self;

	self.mapView.scrollEnabled = NO;
	self.mapView.userInteractionEnabled = NO;
	self.mapView.layer.cornerRadius = 6.0;
	self.mapViewContainer.layer.cornerRadius = 8.0;

	[self.mapView addAnnotation:self.place];
    [self.mapView setRegion:[self.mapView regionForAnnotations:@[self.place]]];

	[self.mapView deselectAnnotation:self.place animated:NO];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Google Map"
																			   style:UIBarButtonItemStylePlain
																			  target:self
																			  action:@selector(externalMapButtonPressed:)];
	
	// never resize the tab view container below this height. 
	self.tabViewContainerMinHeight = CGRectGetHeight(self.tabViewContainer.frame);

	if([self.queryText length]) {
		self.queryLabel.text = [NSString stringWithFormat:@"\"%@\" was found in:", self.queryText];
	} else {
		self.queryLabel.hidden = YES;
		self.nameLabel.frame = CGRectMake(self.nameLabel.frame.origin.x,
                                          self.nameLabel.frame.origin.y - self.queryLabel.frame.size.height,
                                          self.nameLabel.frame.size.width,
                                          self.nameLabel.frame.size.height);
		
		self.locationLabel.frame = CGRectMake(self.locationLabel.frame.origin.x,
                                              self.locationLabel.frame.origin.y - self.queryLabel.frame.size.height,
                                              self.locationLabel.frame.size.width,
                                              self.locationLabel.frame.size.height);
	}
	
    [self loadAnnotationContent];

	if (self.startingTab) {
		self.tabViewControl.selectedTab = self.startingTab;
	}
}

- (void)externalMapButtonPressed:(id)sender
{
	NSString *search = nil;
	
	if (self.place.streetAddress) {
		NSString* desc = self.place.name;
		
		if (self.place.buildingNumber) {
			desc = [desc stringByAppendingFormat:@" - Building %@", self.place.buildingNumber];
		}

		search = [NSString stringWithFormat:@"%lf,%lf(%@)", self.place.coordinate.latitude, self.place.coordinate.longitude, desc];
	} else {
		search = self.place.streetAddress;
	
		// clean up the string
		NSRange parenRange = [search rangeOfString:@"("];
		if (parenRange.location != NSNotFound) {
			search = [search substringToIndex:parenRange.location];
		}

		NSRange accessViaRange = [search rangeOfString:@"Access Via"];
		if (accessViaRange.location != NSNotFound) {
			search = [search substringFromIndex:accessViaRange.length];
		}
		
		if (!self.place.city) {
			search = [search stringByAppendingString:@", Cambridge, MA"];
		} else {
			search = [search stringByAppendingFormat:@", %@", self.place.city];
		}
	}
	
	NSString *url = [NSString stringWithFormat: @"http://maps.google.com/maps?q=%@", [search stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)loadAnnotationContent
{
	[self.loadingResultView removeFromSuperview];
	self.nameLabel.hidden = NO;
	self.locationLabel.hidden = NO;
	
	if ([self.place.contents count]) {
		CGFloat padding = 10.0;
		CGFloat currentHeight = padding;
		CGFloat bulletWidth = 24.0;
		UIFont *whatsHereFont = [UIFont systemFontOfSize:STANDARD_CONTENT_FONT_SIZE];
		for (MITMapPlace *place in self.place.contents) {
            NSString *contentName = place.name;
            
            CGSize textConstraints = CGSizeMake(CGRectGetWidth(self.whatsHereView.frame) - bulletWidth - 2. * padding, 400.0);
			CGSize textSize = [contentName sizeWithFont:whatsHereFont
                                      constrainedToSize:textConstraints
                                          lineBreakMode:NSLineBreakByWordWrapping];

			UILabel *bullet = [[UILabel alloc] initWithFrame:CGRectMake(padding, currentHeight, bulletWidth - padding, 20.0)];
			bullet.text = @"•";
			[self.whatsHereView addSubview:bullet];
			
			UILabel *listItem = [[UILabel alloc] initWithFrame:CGRectMake(bulletWidth, currentHeight, textSize.width, textSize.height)];
			listItem.text = contentName;
			listItem.lineBreakMode = NSLineBreakByWordWrapping;
			listItem.numberOfLines = 0;
			[self.whatsHereView addSubview:listItem];
			
			currentHeight += textSize.height;
		}
		// resize the what's here view to contain the full label
		self.whatsHereView.frame = CGRectMake(self.whatsHereView.frame.origin.x,
                                              self.whatsHereView.frame.origin.y,
                                              self.whatsHereView.frame.size.width,
                                              currentHeight + padding);
		
		
		// resize the content container if the what's here view is bigger than it
		if (CGRectGetHeight(self.whatsHereView.frame) > CGRectGetHeight(self.tabViewContainer.frame)) {

            CGFloat height = MAX(CGRectGetHeight(self.whatsHereView.frame), self.tabViewContainerMinHeight);
			self.tabViewContainer.frame = CGRectMake(_tabViewContainer.frame.origin.x,
                                                     _tabViewContainer.frame.origin.y,
                                                     _tabViewContainer.frame.size.width,
                                                     height);
			
			CGSize contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame),
                                            CGRectGetHeight(self.tabViewContainer.frame) + CGRectGetMinY(self.tabViewContainer.frame));
			[self.scrollView setContentSize:contentSize];
		}
	} else {
		UILabel* noWhatsHereLabel = [[UILabel alloc] initWithFrame:CGRectMake(13, 6, CGRectGetWidth(self.whatsHereView.frame), 20.)];
		noWhatsHereLabel.text = NSLocalizedString(@"No Information Available", nil);
		[self.whatsHereView addSubview:noWhatsHereLabel];
		
	}
	
	[self.tabViewControl addTab:@"What's Here"];
	[self.tabViews addObject:self.whatsHereView];
	
	if (self.place.imageURL) {
        __weak MITMapDetailViewController *weakSelf = self;
        [self.buildingImageView cancelCurrentImageLoad];
        NSURL *imageURL = self.place.imageURL;
        [self.buildingImageView setImageWithURL:imageURL
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                          MITMapDetailViewController *blockSelf = weakSelf;
                                          blockSelf.loadingImageView.hidden = YES;

                                          if (image) {
                                              blockSelf.buildingImageView.image = image;
                                          } else {
                                              blockSelf.buildingImageView.image = nil;
                                          }
                                      }];

        self.buildingImageDescriptionLabel.text = self.place.imageCaption;
		
		[self.tabViewControl addTab:@"Photo"];
		[self.tabViews addObject:self.buildingView];
	}
	
	// if no tabs have been added, remove the tab view control and its container view. 
	if (![self.tabViewControl.tabs count]) {
		self.tabViewControl.hidden = YES;
		self.tabViewContainer.hidden = YES;
	} else {
		self.tabViewControl.hidden = NO;
		self.tabViewContainer.hidden = NO;
	}
	
	[self.tabViewControl setNeedsDisplay];
	[self.tabViewControl setDelegate:self];
	
	
	// set the labels
    NSString *title = [self.place title];
    if ([self.place.subtitle length]) {
        title = [NSString stringWithFormat:@"%@ (%@)",title,self.place.subtitle];
    }


	self.nameLabel.text = title;
	self.nameLabel.numberOfLines = 0;
	CGSize stringSize = [title sizeWithFont:self.nameLabel.font
                          constrainedToSize:CGSizeMake(CGRectGetWidth(self.nameLabel.frame), 200.0)
                              lineBreakMode:NSLineBreakByWordWrapping];

    CGRect nameFrame = self.nameLabel.frame;
    nameFrame.size.height = stringSize.height;
    self.nameLabel.frame = nameFrame;
	
	self.locationLabel.text = self.place.streetAddress;
	CGSize addressSize = [self.place.streetAddress sizeWithFont:self.locationLabel.font
                                              constrainedToSize:CGSizeMake(CGRectGetWidth(self.locationLabel.frame),200.)
                                                  lineBreakMode:NSLineBreakByWordWrapping];
    
    CGRect frame = self.locationLabel.frame;
    frame.origin.y = CGRectGetHeight(self.nameLabel.frame) + CGRectGetMinY(self.nameLabel.frame) + 1.;
    frame.size.height = addressSize.height;
    self.locationLabel.frame = frame;
    
    CGFloat originY = CGRectGetMinY(self.locationLabel.frame) + CGRectGetHeight(self.locationLabel.frame) + 5.;
	
	if (originY > CGRectGetMinY(self.tabViewControl.frame)) {
        frame = self.tabViewControl.frame;
        frame.origin.y = originY;
        self.tabViewControl.frame = frame;
        
        frame = self.tabViewContainer.frame;
        frame.origin.y = CGRectGetMinY(self.tabViewControl.frame) + CGRectGetHeight(self.tabViewControl.frame);

        CGFloat frameHeight = MAX(CGRectGetHeight(self.tabViewContainer.frame),self.tabViewContainerMinHeight);
        frame.size.height = frameHeight;
        self.tabViewControl.frame = frame;
	}
	
	// force the correct tab to load
	if([self.tabViews count]) {
		if (![self.place.contents count] && ([self.tabViews count] > 1)) {
			self.tabViewControl.selectedTab = 1;
			[self tabControl:self.tabViewControl changedToIndex:1 tabText:nil];
		} else {
			self.tabViewControl.selectedTab = 0;
			[self tabControl:self.tabViewControl changedToIndex:0 tabText:nil];
		}
	}
	
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidUnload {
	self.tabViews = nil;
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        // This is used to trigger the setter since, if a place has been assigned,
        // it will need to be transferred into the new context
        self.managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
    }

    return _managedObjectContext;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != managedObjectContext) {
        _managedObjectContext = managedObjectContext;

        if (self.place && _managedObjectContext) {
            self.place = (MITMapPlace*)[_managedObjectContext objectWithID:[self.place objectID]];
        }
    }
}

#pragma mark User Actions
- (IBAction)mapThumbnailPressed:(id)sender
{
    // Do nothing!
}

- (IBAction)bookmarkButtonTapped
{
	if (self.place.bookmark) {
		// remove the bookmark and set the images
		[[MITMapModelController sharedController] removeBookmarkForPlace:self.place completion:^(NSError *error) {
            [[[MITCoreDataController defaultController] mainQueueContext] refreshObject:self.place mergeChanges:NO];

            if (!error) {
                [self.bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off"]
                                     forState:UIControlStateNormal];
                [self.bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_off_pressed"]
                                     forState:UIControlStateHighlighted];
            }

            self.bookmarkButton.enabled = YES;
        }];
	} else {
		[[MITMapModelController sharedController] bookmarkPlaces:@[self.place] completion:^(NSError *error) {
            [[[MITCoreDataController defaultController] mainQueueContext] refreshObject:self.place mergeChanges:NO];

            if (!error) {
                [self.bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on"]
                                     forState:UIControlStateNormal];
                [self.bookmarkButton setImage:[UIImage imageNamed:@"global/bookmark_on_pressed"]
                                     forState:UIControlStateHighlighted];
            }


            self.bookmarkButton.enabled = YES;
        }];
	}

    self.bookmarkButton.enabled = NO;
}

#pragma mark TabViewControlDelegate
-(void) tabControl:(TabViewControl*)control changedToIndex:(int)tabIndex tabText:(NSString*)tabText
{
    [self.tabViewContainer removeAllSubviews];

	// set the size of the scroll view based on the size of the view being added and its parent's offset
	UIView* viewToAdd = self.tabViews[tabIndex];
	self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width,
                                             CGRectGetMinY(self.tabViewContainer.frame) + CGRectGetHeight(viewToAdd.frame));
	
	[self.tabViewContainer addSubview:viewToAdd];
}

@end
