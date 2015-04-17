#import <UIKit/UIKit.h>
#import "MITMobiusResource.h"

typedef void(^MITGalleryHandlerBlock)();

@interface MITMobiusDetailHeader : UIView

@property (nonatomic, copy) MITMobiusResource *resource;
@property (nonatomic, strong) MITGalleryHandlerBlock galleryHandler;

+ (UINib *)titleHeaderNib;
+ (NSString *)titleHeaderNibName;
- (void)setGalleryHandler:(MITGalleryHandlerBlock)galleryHandler;
- (IBAction)didTapImage:(id)sender;

@end