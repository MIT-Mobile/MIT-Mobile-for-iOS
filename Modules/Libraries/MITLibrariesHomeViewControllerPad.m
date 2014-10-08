#import "MITLibrariesHomeViewControllerPad.h"
#import "MITLibrariesYourAccountViewControllerPad.h"

@interface MITLibrariesHomeViewControllerPad ()

@property (nonatomic, strong) MITLibrariesYourAccountViewControllerPad *accountViewController;

@property (nonatomic, strong) UIBarButtonItem *locationsAndHoursButton;
@property (nonatomic, strong) UIBarButtonItem *askUsTellUsButton;
@property (nonatomic, strong) UIBarButtonItem *quickLinksButton;

@end

@implementation MITLibrariesHomeViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;

    [self setupViewControllers];

    [self setupNavBar];
    [self setupToolbar];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavBar
{

}

- (void)setupToolbar
{
    self.navigationController.toolbar.translucent = NO;
    self.locationsAndHoursButton = [[UIBarButtonItem alloc] initWithTitle:@"Locations & Hours" style:UIBarButtonItemStylePlain target:self action:@selector(locationsAndHoursPressed:)];
    self.askUsTellUsButton = [[UIBarButtonItem alloc] initWithTitle:@"Ask Us/Tell Us" style:UIBarButtonItemStylePlain target:self action:@selector(askUsTellUsPressed:)];
    self.quickLinksButton = [[UIBarButtonItem alloc] initWithTitle:@"Quick Links" style:UIBarButtonItemStylePlain target:self action:@selector(quickLinksPressed:)];
    
    CGSize locationsSize = [self.locationsAndHoursButton.title sizeWithAttributes:[self.locationsAndHoursButton titleTextAttributesForState:UIControlStateNormal]];
    CGSize quickLinksSize = [self.quickLinksButton.title sizeWithAttributes:[self.quickLinksButton titleTextAttributesForState:UIControlStateNormal]];
    
    UIBarButtonItem *evenPaddingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    evenPaddingButton.width = locationsSize.width - quickLinksSize.width;
    
    self.toolbarItems = @[self.locationsAndHoursButton,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          self.askUsTellUsButton,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          evenPaddingButton,
                          self.quickLinksButton];
}

- (void)locationsAndHoursPressed:(id)sender
{
    NSLog(@"Locations");
}

- (void)askUsTellUsPressed:(id)sender
{
    NSLog(@"Ask Us");
}

- (void)quickLinksPressed:(id)sender
{
    NSLog(@"Quick Links");
}

- (void)setupViewControllers
{
    self.accountViewController = [[MITLibrariesYourAccountViewControllerPad alloc] init];
    self.accountViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.accountViewController.view.frame = self.view.bounds;
    
    [self addChildViewController:self.accountViewController];
    
    [self.view addSubview:self.accountViewController.view];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[accountView]-0-|" options:0 metrics:nil views:@{@"accountView": self.accountViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[accountView]-0-|" options:0 metrics:nil views:@{@"accountView": self.accountViewController.view}]];
}

@end
