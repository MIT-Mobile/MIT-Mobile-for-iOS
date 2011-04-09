#import <Foundation/Foundation.h>
#import "MITThumbnailView.h"

@class  FeatureLink;

@interface MIT150Button : UIControl <MITThumbnailDelegate>
{
    FeatureLink *_featureLink;
}

@property (nonatomic, retain) FeatureLink *featureLink;

@end
