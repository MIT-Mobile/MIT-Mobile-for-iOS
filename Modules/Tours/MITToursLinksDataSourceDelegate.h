#import <Foundation/Foundation.h>

@class MFMailComposeViewController;

@protocol MITToursLinksDataSourceDelegateDelegate <NSObject>

- (void)presentMailViewController:(MFMailComposeViewController *)mailViewController;

@end

@interface MITToursLinksDataSourceDelegate : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) id<MITToursLinksDataSourceDelegateDelegate> delegate;
@property (nonatomic) BOOL isIphoneTableView;

@end
