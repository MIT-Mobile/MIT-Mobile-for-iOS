#import <UIKit/UIKit.h>
#import "MITMobileWebApi.h"
#import "MITLoadingActivityView.h"

@interface LinksViewController : UIViewController <JSONLoadedDelegate>
{

    BOOL requestWasDispatched;
	MITMobileWebAPI *api;
    MITLoadingActivityView *_loadingView;
    
}

@property (nonatomic, retain) NSArray * linkResults;

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject;
- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error;


@end
