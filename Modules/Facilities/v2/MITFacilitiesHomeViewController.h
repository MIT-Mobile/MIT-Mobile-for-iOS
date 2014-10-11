//
//  MITFacilitiesHomeViewController.h
//  MIT Mobile
//
//

#import <UIKit/UIKit.h>
#import "FacilitiesLocation.h"

@interface MITFacilitiesHomeViewController : UIViewController

@end

@interface MITFacilitiesEditableFieldCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UITextView *subtitleTextView;

@end

@interface MITFacilitiesNonEditableFieldCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;

@end

@interface MITFacilitiesLeasedMessageCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;

@end
