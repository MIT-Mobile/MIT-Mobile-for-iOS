#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MITThumbnailView.h"
#import "ZXingWidgetController.h"

@class CampusTour;

@interface CampusTourInteriorController : UIViewController <MITThumbnailDelegate, 
UIAlertViewDelegate, UINavigationControllerDelegate, ZXingDelegate,
CLLocationManagerDelegate> {
    
    IBOutlet UIButton *overviewButton;
    IBOutlet UIButton *qrButton;
    
    CampusTour *tour;
    
}

@property (nonatomic, assign) CampusTour *tour;

- (IBAction)qrcodeButtonPressed:(id)sender;
- (IBAction)overviewButtonPressed:(id)sender;

@end
