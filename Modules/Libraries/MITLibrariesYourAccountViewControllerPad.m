#import "MITLibrariesYourAccountViewControllerPad.h"
#import "UIKit+MITAdditions.h"
#import "MITTouchstoneController.h"
#import "MITLibrariesYourAccountListViewControllerPad.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesUser.h"
#import "MITLibrariesYourAccountGridViewControllerPad.h"

@interface MITLibrariesYourAccountViewControllerPad ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIButton *logInButton;
@property (weak, nonatomic) IBOutlet UIView *loginView;

@property (nonatomic, strong) MITLibrariesYourAccountListViewControllerPad *listViewController;
@property (nonatomic, strong) MITLibrariesYourAccountGridViewControllerPad *gridViewController;

@end

@implementation MITLibrariesYourAccountViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [self setupViewControllers];
    [self setupLoginView];
    
    if ([MITTouchstoneController sharedController].isLoggedIn) {
        [self refreshUserData];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];  
}

- (void)applicationDidBecomeActive
{
    [self refreshUserData];
}

- (void)setupLoginView
{
    self.logInButton.tintColor = [UIColor mit_tintColor];
    [self showHideLoginView];
}

- (void)setupViewControllers
{
    self.listViewController = [[MITLibrariesYourAccountListViewControllerPad alloc] initWithStyle:UITableViewStylePlain];
    self.listViewController.view.frame = self.view.bounds;
    [self addChildViewController:self.listViewController];
    
    self.gridViewController = [[MITLibrariesYourAccountGridViewControllerPad alloc] initWithNibName:nil bundle:nil];
    self.gridViewController.view.frame = self.view.bounds;
    [self addChildViewController:self.gridViewController];
    
    [self showCurrentlySelectedViewController];
    
    [self.view addSubview:self.listViewController.view];
    [self.view addSubview:self.gridViewController.view];
}

- (void)setLayoutMode:(MITLibrariesLayoutMode)layoutMode
{
    if (_layoutMode == layoutMode) {
        return;
    }
    
    _layoutMode = layoutMode;
    
    [self showCurrentlySelectedViewController];
}

- (IBAction)logInButtonPressed:(UIButton *)sender
{
    [[MITTouchstoneController sharedController] login:^(BOOL success, NSError *error) {
        [self showHideLoginView];
        [self refreshUserData];
    }];
}

- (void)showHideLoginView
{
    if ([MITTouchstoneController sharedController].isLoggedIn) {
        self.loginView.hidden = YES;
        [self showCurrentlySelectedViewController];
    }
    else {
        self.loginView.hidden = NO;
        [self hideViewControllers];
    }
}

- (void)hideViewControllers
{
    self.listViewController.view.hidden = YES;
    self.gridViewController.view.hidden = YES;
}

- (void)showCurrentlySelectedViewController
{
    switch (self.layoutMode) {
        case MITLibrariesLayoutModeList: {
            self.listViewController.view.hidden = NO;
            self.gridViewController.view.hidden = YES;
            break;
        }
        case MITLibrariesLayoutModeGrid: {
            self.listViewController.view.hidden = YES;
            self.gridViewController.view.hidden = NO;
            break;
        }
    }
}

- (void)refreshUserData
{
    [self hideViewControllers];
    self.loadingIndicator.hidden = NO;
    [self.loadingIndicator startAnimating];
    
    [MITLibrariesWebservices getUserWithCompletion:^(MITLibrariesUser *user, NSError *error) {
        if (!error) {
            self.listViewController.user = user;
            self.gridViewController.user = user;
            [self showCurrentlySelectedViewController];
        }
        [self.loadingIndicator stopAnimating];
        self.loadingIndicator.hidden = YES;
    }];
}

@end
