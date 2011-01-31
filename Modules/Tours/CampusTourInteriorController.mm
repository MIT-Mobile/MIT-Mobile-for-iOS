#import "CampusTourInteriorController.h"
#import "CoreDataManager.h"
#import "MIT_MobileAppDelegate.h"
#import "QRCodeReader.h"
#import "TourComponent.h"
#import "TourOverviewViewController.h"
#import "CampusTour.h"

#define QR_CODE_ALERT_VIEW 28

static NSString * const QRAlertUserDefaultString = @"QRCodeAlertDidShow";

@implementation CampusTourInteriorController

@synthesize tour;

- (IBAction)qrcodeButtonPressed:(id)sender {
    ZXingWidgetController *widController = [[[ZXingWidgetController alloc] initWithDelegate:self showCancel:YES OneDMode:NO] autorelease];
    QRCodeReader* qrcodeReader = [[[QRCodeReader alloc] init] autorelease];
    NSSet *readers = [NSSet setWithObjects:qrcodeReader, nil];
    widController.readers = readers;
    widController.soundToPlay = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tours/beep-beep" ofType:@"aiff"] isDirectory:NO];
    
    [self.navigationController setNavigationBarHidden:YES];
    for (UIView *aView in self.view.subviews) {
        aView.hidden = YES;
    }
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate presentAppModalViewController:widController animated:YES];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:QRAlertUserDefaultString]) {
        NSString *message = NSLocalizedString(@"QR_CODE_HINT", nil);
        
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Scan QR Code"
                                                             message:message
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:@"Scan", nil] autorelease];
        alertView.tag = QR_CODE_ALERT_VIEW;
        [alertView show];
    }
}

- (IBAction)overviewButtonPressed:(id)sender {
    TourOverviewViewController *vc = [[[TourOverviewViewController alloc] init] autorelease];
    vc.tour = self.tour;
    vc.callingViewController = self;
	UINavigationController *dummyNavC = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate presentAppModalViewController:dummyNavC animated:YES];
}

#pragma mark MITThumbnailDelegate

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == QR_CODE_ALERT_VIEW) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:QRAlertUserDefaultString];
        [[NSUserDefaults standardUserDefaults] synchronize];

        if (buttonIndex == [alertView cancelButtonIndex]) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
            [self zxingControllerDidCancel:nil];
        }
    }
}

#pragma mark ZXingDelegate

- (void)zxingController:(ZXingWidgetController*)controller didScanResult:(NSString *)result {
    // TODO: push "QR Code Result" screen behind modal VC
    [self.navigationController setNavigationBarHidden:NO];
    for (UIView *aView in self.view.subviews) {
        aView.hidden = NO;
    }
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate dismissAppModalViewControllerAnimated:YES];
}

- (void)zxingControllerDidCancel:(ZXingWidgetController*)controller {
    [self.navigationController setNavigationBarHidden:NO];
    for (UIView *aView in self.view.subviews) {
        aView.hidden = NO;
    }
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate dismissAppModalViewControllerAnimated:YES];
}

#pragma mark UIViewController

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/
/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.appModalHolder.modalViewController) {
        return [appDelegate.appModalHolder.modalViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.appModalHolder.modalViewController) {
        [appDelegate.appModalHolder.modalViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.appModalHolder.modalViewController) {
        [appDelegate.appModalHolder.modalViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
}
*/
#pragma mark Memory

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
