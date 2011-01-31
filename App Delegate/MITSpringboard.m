#import "MITSpringboard.h"
#import "IconGrid.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModule.h"
#import "DummyRotatingViewController.h"
#import "ScrollFadeImageView.h"

@interface MITSpringboard (Private)

- (void)showModuleForIcon:(id)sender;
- (void)showModuleForBanner;
- (void)checkForFeaturedModule;
- (void)displayBannerImage;

@end

#define BANNER_CONTROL_TAG 9966

@implementation MITSpringboard

@synthesize primaryModules, delegate, connection;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (void)showModuleForIcon:(id)sender {
    SpringboardIcon *icon = (SpringboardIcon *)sender;
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showModuleForTag:icon.moduleTag];
}

- (void)showModuleForBanner {
    NSString *bannerURL = [bannerInfo objectForKey:@"url"];
	if (bannerURL) {
		NSURL *url = [NSURL URLWithString:bannerURL];
		if ([[UIApplication sharedApplication] canOpenURL:url]) {
			[[UIApplication sharedApplication] openURL:url];
		}
	}
}

- (void)checkForFeaturedModule {
	MITMobileWebAPI *api = [MITMobileWebAPI jsonLoadedDelegate:self];
	[api requestObjectFromModule:@"features" command:@"banner" parameters:nil];
}

- (void)displayBannerImage {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    NSString *bannerFile = [documentPath stringByAppendingPathComponent:@"banner"];

    //NSLog(@"%@", [bannerInfo description]);
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:bannerFile]) {
		UIImage *image = [[UIImage imageWithContentsOfFile:bannerFile] stretchableImageWithLeftCapWidth:0.0 topCapHeight:0.0];
        if (!image) return;
        
        CGFloat bannerWidth = [[bannerInfo objectForKey:@"width"] floatValue];
        if (!bannerWidth)  bannerWidth = self.view.frame.size.width;
        CGFloat bannerHeight = [[bannerInfo objectForKey:@"height"] floatValue];
        if (!bannerHeight) bannerHeight = 72;
        
		UIImageView *imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
		imageView.userInteractionEnabled = NO;
        imageView.frame = CGRectMake(0, 0, bannerWidth, bannerHeight);
		
		UIControl *control = (UIControl *)[self.view viewWithTag:BANNER_CONTROL_TAG];
		if (control)
			[control removeFromSuperview];
		control = [[[UIControl alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - bannerHeight, bannerWidth, bannerHeight)] autorelease];
        control.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		control.tag = BANNER_CONTROL_TAG;
		[control addSubview:imageView];
		[control addTarget:self action:@selector(showModuleForBanner) forControlEvents:UIControlEventTouchUpInside];
		
		[self.view addSubview:control];
	}
}

#pragma mark JSONLoadedDelegate

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject {
	if (JSONObject && [JSONObject isKindOfClass:[NSDictionary class]]) {
		
		NSNumber *showBanner = [JSONObject objectForKey:@"showBanner"];
		if (!showBanner || ![showBanner boolValue]) {
			
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			NSString *documentPath = [paths objectAtIndex:0];
			
			NSString *bannerURLFile = [documentPath stringByAppendingPathComponent:@"bannerInfo.plist"];
			NSString *bannerFile = [documentPath stringByAppendingPathComponent:@"banner"];
			
			NSError *error = nil;
			[[NSFileManager defaultManager] removeItemAtPath:bannerURLFile error:&error];
			[[NSFileManager defaultManager] removeItemAtPath:bannerFile error:&error];
			
			UIControl *control = (UIControl *)[self.view viewWithTag:BANNER_CONTROL_TAG];
			if (control)
				[control removeFromSuperview];
			
			return;
		}
		
		NSDictionary *dimensions = [JSONObject objectForKey:@"dimensions"];
		if (dimensions) {
            NSNumber *width = [dimensions objectForKey:@"width"];
            if (width) [bannerInfo setObject:width forKey:@"width"];
            NSNumber *height = [dimensions objectForKey:@"height"];
            if (height) [bannerInfo setObject:height forKey:@"height"];
		}

        NSString *url = [JSONObject objectForKey:@"url"];
        if (url) [bannerInfo setObject:url forKey:@"url"];
        
		NSString *photoURL = [JSONObject objectForKey:@"photo-url"];
        if (photoURL) {

            NSString *oldPhotoURL = [[bannerInfo objectForKey:@"photo-url"] retain];
            [bannerInfo setObject:photoURL forKey:@"photo-url"];

            if (![oldPhotoURL isEqualToString:photoURL] // new image
                || ![self.view viewWithTag:BANNER_CONTROL_TAG]) // or we haven't displayed the image
            {
                [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] showNetworkActivityIndicator];
                
                self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
                [self.connection requestDataFromURL:[NSURL URLWithString:photoURL] allowCachedResponse:YES];

            } else { // redraw the image anyway, in case they changed something other than the photoURL
                [self displayBannerImage];
            }
            [oldPhotoURL release];
        }
		
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = [paths objectAtIndex:0];
        NSString *bannerInfoFile = [documentPath stringByAppendingPathComponent:@"bannerInfo.plist"];
        [bannerInfo writeToFile:bannerInfoFile atomically:YES];
	}
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error {
	return NO;
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	NSLog(@"request failed, using cache");
}

#pragma mark ConnectionWrapper

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    UIImage *image = [UIImage imageWithData:data];
    if (image) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = [paths objectAtIndex:0];
        NSString *bannerFile = [documentPath stringByAppendingPathComponent:@"banner"];
        NSLog(@"writing to %@", bannerFile);
        NSError *error = nil;
        if (![data writeToFile:bannerFile options:NSDataWritingAtomic error:&error]) {
            NSLog(@"%@", [error description]);
        }
    }
    
    [self displayBannerImage];
    
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
    self.connection = nil;
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
    [(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] hideNetworkActivityIndicator];
    self.connection = nil;
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	NSInteger newStackDepth = navigationController.viewControllers.count;
	if (newStackDepth < navStackDepth) {
		if ([self.delegate respondsToSelector:@selector(springboardDidPopModule:)]) {
			[self.delegate springboardDidPopModule:self];
		}
	} else {
		NSString *tag = nil;
		for (MITModule *aModule in self.primaryModules) {
			if ([navigationController.viewControllers containsObject:aModule.tabNavController.visibleViewController]) {
				tag = aModule.tag;
				break;
			}
		}
		if (tag) {
			if ([self.delegate respondsToSelector:@selector(springboard:didPushModuleForTag:)]) {
				[self.delegate springboard:self didPushModuleForTag:tag];
			}
		}
	}
	navStackDepth = newStackDepth;
}

#pragma mark -

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Home";
    UIImage *logoView = [UIImage imageNamed:@"global/navbar_mit_logo.png"];
    self.navigationItem.titleView = [[[UIImageView alloc] initWithImage:logoView] autorelease];

    // TODO: fix placeholder dimensions
    IconGrid *grid = [[[IconGrid alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)] autorelease];
    grid.padding = GridPaddingMake(10, 21, 10, 21);
    grid.spacing = GridSpacingMake(30, 10);
    grid.maxColumns = 3;
    NSMutableArray *buttons = [NSMutableArray array];
    UIFont *font = [UIFont boldSystemFontOfSize:12];
    for (MITModule *aModule in self.primaryModules) {
        SpringboardIcon *aButton = [SpringboardIcon buttonWithType:UIButtonTypeCustom];
        [aButton setImage:aModule.springboardIcon forState:UIControlStateNormal];
        [aButton setTitle:aModule.shortName forState:UIControlStateNormal];
        [aButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        aButton.moduleTag = aModule.tag;
        aModule.springboardButton = aButton;
        
        CGFloat titleHPadding = 10;
        CGFloat titleVPadding = 1;
        CGFloat titleHeight = 18;
        aButton.frame = CGRectMake(0, 0,
                                   aModule.springboardIcon.size.width + titleHPadding * 2,
                                   aModule.springboardIcon.size.height + titleHeight + titleVPadding * 2);
        aButton.imageEdgeInsets = UIEdgeInsetsMake(0, titleHPadding, titleHeight, titleHPadding);
        aButton.titleEdgeInsets = UIEdgeInsetsMake(aModule.springboardIcon.size.height + titleVPadding,
                                                   -aModule.springboardIcon.size.width, titleVPadding, 0);
        aButton.titleLabel.font = font;
        [aButton addTarget:self action:@selector(showModuleForIcon:) forControlEvents:UIControlEventTouchUpInside];
        [buttons addObject:aButton];
    }
    grid.icons = buttons;
    [self.view addSubview:grid];
	
    // prep data for showing banner
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    NSString *bannerInfoFile = [documentPath stringByAppendingPathComponent:@"bannerInfo.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:bannerInfoFile]) {
        bannerInfo = [[NSDictionary dictionaryWithContentsOfFile:bannerInfoFile] retain];
    }
    if (!bannerInfo) {
        bannerInfo = [[NSMutableDictionary alloc] init];
    }
    
    [self displayBannerImage];
	[self checkForFeaturedModule];

	checkBannerTimer = [[NSTimer scheduledTimerWithTimeInterval:60 * 60 * 12
														 target:self 
													   selector:@selector(checkForFeaturedModule)
													   userInfo:nil 
														repeats:YES] retain];

    /*
    IconGrid *secondGrid = [[[IconGrid alloc] initWithFrame:CGRectMake(0, 320, 320, 110)] autorelease];
    NSMutableArray *secondButtons = [NSMutableArray array];
    secondGrid.padding = GridPaddingMake(20, 20, 20, 20);
    secondGrid.spacing = GridSpacingMake(20, 20);
    for (MITModule *aModule in self.secondaryModules) {
        SpringboardIcon *aButton = [SpringboardIcon buttonWithType:UIButtonTypeCustom];
        [aButton setImage:aModule.springboardIcon forState:UIControlStateNormal];
        [aButton setTitle:aModule.shortName forState:UIControlStateNormal];
        [aButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        aButton.moduleTag = aModule.tag;
        aButton.frame = CGRectMake(0, 0, aModule.springboardIcon.size.width + 10, aModule.springboardIcon.size.height + 31);
        aButton.imageEdgeInsets = UIEdgeInsetsMake(0, 5, 21, 5);
        aButton.titleEdgeInsets = UIEdgeInsetsMake(aModule.springboardIcon.size.height + 5, -aModule.springboardIcon.size.width, 0, 0);
        aButton.titleLabel.font = font;
        [aButton addTarget:self action:@selector(showModuleForIcon:) forControlEvents:UIControlEventTouchUpInside];
        [secondButtons addObject:aButton];
    }
    secondGrid.icons = secondButtons;
    [self.view addSubview:secondGrid];
    */
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // force the visible viewController to reload its view.
    // without this, all modules except Stellar (still trying to find out why)
    // drop their view without reloading again until going back in the nav stack.
    UIViewController *viewController = nil;
    if (self.navigationController.visibleViewController != self) {
        viewController = [self.navigationController popViewControllerAnimated:NO];
        [self.navigationController pushViewController:viewController animated:NO];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	self.primaryModules = nil;
	[checkBannerTimer release];
	[bannerInfo release];
    [super dealloc];
}


@end

@implementation SpringboardIcon

@synthesize moduleTag;
@synthesize badgeValue;

- (NSString *)badgeValue {
    return badgeValue;
}

#define BADGE_TAG 62
#define BADGE_LABEL_TAG 63
- (void)setBadgeValue:(NSString *)newValue {
    [badgeValue release];
    badgeValue = [newValue retain];
    
    UIView *badgeView = [self viewWithTag:BADGE_TAG];

    if (badgeValue) {
        UIFont *labelFont = [UIFont boldSystemFontOfSize:13.0f];
        
        if (!badgeView) {
            UIImage *image = [UIImage imageNamed:@"global/icon-badge.png"];
            UIImage *stretchableImage = [image stretchableImageWithLeftCapWidth:floor(image.size.width / 2) - 1 topCapHeight:0];
            
            badgeView = [[[UIImageView alloc] initWithImage:stretchableImage] autorelease];
            badgeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
            badgeView.tag = BADGE_TAG;
            
            UILabel *badgeLabel = [[[UILabel alloc] initWithFrame:badgeView.frame] autorelease];
            badgeLabel.backgroundColor = [UIColor clearColor];
            badgeLabel.textColor = [UIColor whiteColor];
            badgeLabel.font = labelFont;
            badgeLabel.textAlignment = UITextAlignmentCenter;
            badgeLabel.tag = BADGE_LABEL_TAG;
            [badgeView addSubview:badgeLabel];
        }
        UILabel *badgeLabel = (UILabel *)[badgeView viewWithTag:BADGE_LABEL_TAG];
        CGSize size = [badgeValue sizeWithFont:labelFont];
        CGFloat padding = 7.0;
        CGRect frame = badgeView.frame;
        
        if (size.width + 2 * padding > frame.size.width) {
            // resize label for more digits
            frame.size.width = size.width;
            frame.origin.x += padding;
            badgeLabel.frame = frame;
            
            // resize bubble
            frame = badgeView.frame;
            frame.size.width = size.width + padding * 2;
            badgeView.frame = frame;
        }
        badgeLabel.text = badgeValue;

        // place badgeView on top right corner
        frame.origin = CGPointMake(self.frame.size.width - floor(badgeView.frame.size.width / 2) - 5,
                                   - floor(badgeView.frame.size.height / 2) + 5);
        badgeView.frame = frame;
        
        [self addSubview:badgeView];
    } else {
        [badgeView removeFromSuperview];
    }
}

- (void)dealloc {
    self.badgeValue = nil;
    self.moduleTag = nil;
    [super dealloc];
}

@end
