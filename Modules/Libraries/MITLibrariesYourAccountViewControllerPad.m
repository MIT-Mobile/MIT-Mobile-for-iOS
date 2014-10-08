#import "MITLibrariesYourAccountViewControllerPad.h"
#import "UIKit+MITAdditions.h"
#import "MITTouchstoneController.h"

@interface MITLibrariesYourAccountViewControllerPad ()
@property (weak, nonatomic) IBOutlet UIButton *logInButton;
@property (weak, nonatomic) IBOutlet UIView *loginView;

@end

@implementation MITLibrariesYourAccountViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupLoginView];
}

- (void)setupLoginView
{
    self.logInButton.tintColor = [UIColor mit_tintColor];
    [self showHideLoginView];
}

- (IBAction)logInButtonPressed:(UIButton *)sender
{
    [[MITTouchstoneController sharedController] login:^(BOOL success, NSError *error) {
        [self showHideLoginView];
    }];
}

- (void)showHideLoginView
{
    self.loginView.hidden = [MITTouchstoneController sharedController].isLoggedIn;
}

@end
