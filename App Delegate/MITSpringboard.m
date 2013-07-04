#import "MITSpringboard.h"
#import "IconGrid.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModule.h"
#import "DummyRotatingViewController.h"
#import "ScrollFadeImageView.h"
#import "MITMobileServerConfiguration.h"
#import "MobileRequestOperation.h"

@interface MITSpringboard ()
@property (nonatomic, retain) NSMutableDictionary *bannerInfo;

- (void)internalInit;
- (void)showModuleForIcon:(id)sender;
- (void)showModuleForBanner;
- (void)checkForFeaturedModule;
- (void)displayBannerImage;
@end

#define BANNER_CONTROL_TAG 9966

@implementation MITSpringboard
@synthesize grid, primaryModules, delegate;

- (id)init
{
    self = [super init];
    if (self) {
        [self internalInit];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self) {
        [self internalInit];
    }
    
    return self;
}

- (void)internalInit
{
    /* Do Nothing */
}

- (void)showModuleForIcon:(id)sender {
    SpringboardIcon *icon = (SpringboardIcon *)sender;
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showModuleForTag:icon.moduleTag];
}

- (void)showModuleForBanner {
    NSString *bannerURL = [self.bannerInfo objectForKey:@"url"];
	if (bannerURL) {
		NSURL *url = [NSURL URLWithString:bannerURL];
		if ([[UIApplication sharedApplication] canOpenURL:url]) {
			[[UIApplication sharedApplication] openURL:url];
		}
	}
}

- (void)checkForFeaturedModule {
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithRelativePath:@"apis/apps/banners" parameters:nil] autorelease];
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSString *contentType, NSError *error) {
        
        if (!error && [jsonResult isKindOfClass:[NSDictionary class]]) {
            
            NSNumber *showBanner = [jsonResult objectForKey:@"showBanner"];
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
            
            NSDictionary *dimensions = [jsonResult objectForKey:@"dimensions"];
            if (dimensions) {
                NSNumber *width = [dimensions objectForKey:@"width"];
                if (width) [self.bannerInfo setObject:width forKey:@"width"];
                NSNumber *height = [dimensions objectForKey:@"height"];
                if (height) [self.bannerInfo setObject:height forKey:@"height"];
            }
            
            NSString *url = [jsonResult objectForKey:@"url"];
            if (url) [self.bannerInfo setObject:url forKey:@"url"];
            
            NSString *photoURL = [jsonResult objectForKey:@"photo-url"];
            if (photoURL) {
                NSString *oldPhotoURL = [[[self.bannerInfo objectForKey:@"photo-url"] retain] autorelease];
                [self.bannerInfo setObject:photoURL forKey:@"photo-url"];

                if (![oldPhotoURL isEqualToString:photoURL] // new image
                    || ![self.view viewWithTag:BANNER_CONTROL_TAG]) // or we haven't displayed the image
                {
                    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithURL:[NSURL URLWithString:photoURL] parameters:nil] autorelease];
                    request.completeBlock = ^(MobileRequestOperation *request, NSData *data, NSString *contentType, NSError *error) {
                        if (error) {
                            
                        } else {
                            UIImage *image = [UIImage imageWithData:data];
                            if (image) {
                                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                NSString *documentPath = [paths objectAtIndex:0];
                                NSString *bannerFile = [documentPath stringByAppendingPathComponent:@"banner"];
                                DDLogVerbose(@"writing to %@", bannerFile);
                                NSError *error = nil;
                                if (![data writeToFile:bannerFile options:NSDataWritingAtomic error:&error]) {
                                    DDLogError(@"%@", [error description]);
                                }
                            }
                            
                            [self displayBannerImage];
                        }
                    };
                    [[NSOperationQueue mainQueue] addOperation:request];
                } else { // redraw the image anyway, in case they changed something other than the photoURL
                    [self displayBannerImage];
                }
            }
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentPath = [paths objectAtIndex:0];
            NSString *bannerInfoFile = [documentPath stringByAppendingPathComponent:@"bannerInfo.plist"];
            [self.bannerInfo writeToFile:bannerInfoFile atomically:YES];
        }
    };
    [[NSOperationQueue mainQueue] addOperation:request];
}

- (void)displayBannerImage {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    NSString *bannerFile = [documentPath stringByAppendingPathComponent:@"banner"];

	if ([[NSFileManager defaultManager] fileExistsAtPath:bannerFile]) {
		UIImage *image = [[UIImage imageWithContentsOfFile:bannerFile] stretchableImageWithLeftCapWidth:0.0 topCapHeight:0.0];
        if (!image) return;
        
        CGFloat bannerWidth = [[self.bannerInfo objectForKey:@"width"] floatValue];
        if (!bannerWidth)  bannerWidth = self.view.frame.size.width;
        CGFloat bannerHeight = [[self.bannerInfo objectForKey:@"height"] floatValue];
        if (!bannerHeight) bannerHeight = 72;
        
		UIButton *bannerButton = (UIButton *)[self.view viewWithTag:BANNER_CONTROL_TAG];
        if (bannerButton) {
            [bannerButton removeFromSuperview];
        }
        bannerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        bannerButton.frame = CGRectMake(0, self.view.frame.size.height - bannerHeight, bannerWidth, bannerHeight);
        bannerButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        bannerButton.tag = BANNER_CONTROL_TAG;
        [bannerButton setImage:image forState:UIControlStateNormal];
        [bannerButton addTarget:self action:@selector(showModuleForBanner) forControlEvents:UIControlEventTouchUpInside];
        		
		[self.view addSubview:bannerButton];
        
        // will trigger a relayout of grid if the frame is different
        CGRect newGridFrame = grid.frame;
        newGridFrame.size.height = self.view.frame.size.height - bannerButton.frame.size.height;
        grid.frame = newGridFrame;
	}
}

- (void)pushModuleWithTag:(NSString *)tag
{
    if ([tag isEqualToString:MobileWebTag]) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", MITMobileWebGetCurrentServerDomain()]];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
        
        return;
    }

    for (MITModule *module in self.primaryModules) {
        if ([[module tag] isEqualToString:tag]) {
            if ([self.delegate respondsToSelector:@selector(springboard:willPushModule:)]) {
                [self.delegate springboard:self
                            willPushModule:module];
            }
            
            [self.navigationController pushViewController:module.moduleHomeController
                                                 animated:YES];
            
            if ([self.delegate respondsToSelector:@selector(springboard:didPushModule:)]) {
                [self.delegate springboard:self
                             didPushModule:module];
            }
            
            module.hasLaunchedBegun = YES;
            [module didAppear];
        }
    }
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    if (viewController == self)
    {
        [navigationController setToolbarHidden:YES
                                      animated:YES];
    }
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    
}

#pragma mark UIViewController

- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark -

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Home";
    UIImage *logoView = [UIImage imageNamed:@"global/navbar_mit_logo.png"];
    self.navigationItem.titleView = [[[UIImageView alloc] initWithImage:logoView] autorelease];

    self.grid = [[[IconGrid alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)] autorelease];
    self.grid.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.grid setHorizontalMargin:5.0 vertical:10.0];
    [self.grid setHorizontalPadding:5.0 vertical:10.0];
    [self.grid setMinimumColumns:4 maximum:4];

    NSMutableArray *buttons = [NSMutableArray array];
    UIFont *font = [UIFont boldSystemFontOfSize:12];
    for (MITModule *aModule in self.primaryModules) {
        SpringboardIcon *aButton = [SpringboardIcon buttonWithType:UIButtonTypeCustom];
        [aButton setImage:aModule.springboardIcon forState:UIControlStateNormal];
        [aButton setTitle:aModule.shortName forState:UIControlStateNormal];
        [aButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        aButton.moduleTag = aModule.tag;
        aModule.springboardButton = aButton;
        
        CGFloat titleHPadding = 15;
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
    self.grid.icons = buttons;
    [self.view addSubview:self.grid];
	
    // prep data for showing banner
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    NSString *bannerInfoFile = [documentPath stringByAppendingPathComponent:@"bannerInfo.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:bannerInfoFile]) {
        self.bannerInfo = [NSDictionary dictionaryWithContentsOfFile:bannerInfoFile];
    }
    if (!self.bannerInfo) {
        self.bannerInfo = [[[NSMutableDictionary alloc] init] autorelease];
    }
    
    [self displayBannerImage];
	[self checkForFeaturedModule];

	checkBannerTimer = [[NSTimer scheduledTimerWithTimeInterval:60 * 60 * 12
														 target:self 
													   selector:@selector(checkForFeaturedModule)
													   userInfo:nil 
														repeats:YES] retain];
}


- (void)dealloc {
	self.primaryModules = nil;
	[checkBannerTimer release];
    self.bannerInfo = nil;
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
            UIImage *stretchableImage = [image stretchableImageWithLeftCapWidth:(NSUInteger)(floor(image.size.width / 2) - 1)
                                                                   topCapHeight:0];
            
            badgeView = [[[UIImageView alloc] initWithImage:stretchableImage] autorelease];
            badgeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
            badgeView.tag = BADGE_TAG;
            
            UILabel *badgeLabel = [[[UILabel alloc] initWithFrame:badgeView.frame] autorelease];
            badgeLabel.backgroundColor = [UIColor clearColor];
            badgeLabel.textColor = [UIColor whiteColor];
            badgeLabel.font = labelFont;
            badgeLabel.textAlignment = NSTextAlignmentCenter;
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
