#import <UIKit/UIKit.h>


@interface FacilitiesRootViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITextView *_textView;
    UITableView *_tableView;
    BOOL _isLoadingData;
}

@property (nonatomic,readonly,retain) IBOutlet UITextView *textView;
@property (nonatomic,readonly,retain) IBOutlet UITableView* tableView;

@end
