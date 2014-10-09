#import "MITLibrariesYourAccountViewControllerPad.h"
#import "UIKit+MITAdditions.h"
#import "MITTouchstoneController.h"
#import "MITLibrariesYourAccountListViewControllerPad.h"
#import "MITLibrariesWebservices.h"
#import "MITLibrariesUser.h"

@interface MITLibrariesYourAccountViewControllerPad ()

@property (weak, nonatomic) IBOutlet UIButton *logInButton;
@property (weak, nonatomic) IBOutlet UIView *loginView;

@property (nonatomic, strong) MITLibrariesYourAccountListViewControllerPad *listViewController;

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
    
    [self.view addSubview:self.listViewController.view];
    
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
        self.listViewController.view.hidden = NO;
    }
    else {
        self.loginView.hidden = NO;
        self.listViewController.view.hidden = YES;
    }
}

- (void)refreshUserData
{
    [MITLibrariesWebservices getUserWithCompletion:^(MITLibrariesUser *user, NSError *error) {
        if (!error) {
            self.listViewController.user = user;
        }
    }];
}

@end
