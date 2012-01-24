#import "MIT150Button.h"
#import "FeatureLink.h"
#import "CoreDataManager.h"
#import "UIKit+MITAdditions.h"
#import <QuartzCore/QuartzCore.h>


@implementation MIT150Button

@synthesize featureLink = _featureLink;

- (void)setFeatureLink:(FeatureLink *)newFeatureLink {
    [_featureLink release];
    _featureLink = [newFeatureLink retain];
    
    CGRect frame = self.frame;
    frame.size.width = _featureLink.size.width;
    frame.size.height = _featureLink.size.height;
    self.frame = frame;
    
    [self addTarget:self action:@selector(wasTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 5.0;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.frame;
    frame.origin = CGPointZero;
    
    // background
    MITThumbnailView *thumbnail = (MITThumbnailView *)[self viewWithTag:8001];
    if (!thumbnail) {
        thumbnail = [[[MITThumbnailView alloc] initWithFrame:frame] autorelease];
        thumbnail.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        thumbnail.delegate = self;
        thumbnail.tag = 8001;
        thumbnail.userInteractionEnabled = NO;
        [self addSubview:thumbnail];
    } else {
        thumbnail.frame = frame;
    }
    if (self.featureLink.photo) {
        thumbnail.imageData = self.featureLink.photo;
    } else {
        thumbnail.imageURL = self.featureLink.photoURL;
    }
    [thumbnail loadImage];
    
    UIColor *tintColor = [UIColor colorWithHexString:self.featureLink.tintColor];
    UIColor *titleColor = tintColor;
	UIColor *arrowColor = tintColor;
    
    if (self.featureLink.titleColor) {
        titleColor = [UIColor colorWithHexString:self.featureLink.titleColor];
    }
    if (self.featureLink.arrowColor) {
        arrowColor = [UIColor colorWithHexString:self.featureLink.arrowColor];
    }
    
    if (self.featureLink.title && !self.featureLink.subtitle) {
        // title
        UIFont *font = [UIFont boldSystemFontOfSize:13];
        CGSize size = [self.featureLink.title sizeWithFont:font];
        frame = CGRectMake(10, 4, self.frame.size.width - 20, size.height);
        
        UILabel *titleLabel = (UILabel *)[self viewWithTag:8003];
        if (!titleLabel) {
            titleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.font = font;
            titleLabel.tag = 8003;
            titleLabel.userInteractionEnabled = NO;
            titleLabel.text = self.featureLink.title;
            [self addSubview:titleLabel];
        } else {
            titleLabel.frame = frame;
        }
        
        // disclosure
        CGRect triangleFrame = CGRectMake(titleLabel.frame.origin.x + size.width, titleLabel.frame.origin.y, 10, titleLabel.frame.size.height);
        UILabel *triangleLabel = (UILabel *)[self viewWithTag:8005];
        if (!triangleLabel) {
            triangleLabel = [[[UILabel alloc] initWithFrame:triangleFrame] autorelease];
            triangleLabel.textColor = arrowColor;
            triangleLabel.font = [UIFont systemFontOfSize:10];
            triangleLabel.text = @"\u25b6";
            triangleLabel.backgroundColor = [UIColor clearColor];
            triangleLabel.tag = 8005;
            [self addSubview:triangleLabel];
        } else {
            triangleLabel.frame = triangleFrame;
        }
        
    } else if (self.featureLink.subtitle) {
        
        // overlay
        frame.origin.y = round(self.frame.size.height * 0.6);
        frame.size.height = round(self.frame.size.height * 0.4);
        
        UIView *overlay = [self viewWithTag:8002];
        if (!overlay) {
            CGFloat * colorComps = (CGFloat *)CGColorGetComponents([tintColor CGColor]);
            
            UIView *overlay = [[[UIView alloc] initWithFrame:frame] autorelease];
            overlay.userInteractionEnabled = NO;
            overlay.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            overlay.backgroundColor = [UIColor colorWithRed:colorComps[0] * 0.3
                                                      green:colorComps[1] * 0.3
                                                       blue:colorComps[2] * 0.3
                                                      alpha:0.6];
            overlay.tag = 8002;
            [self addSubview:overlay];
        }
        
        // title
        frame.origin.x += 10;
        frame.origin.y += 8;
        frame.size.width -= 20;
        
        UIFont *font = [UIFont fontWithName:@"Georgia-Italic" size:14];
        CGSize size = [self.featureLink.title sizeWithFont:font];
        frame.size.height = size.height;
        
        UILabel *titleLabel = (UILabel *)[self viewWithTag:8003];
        if (!titleLabel) {
            titleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = titleColor;
            titleLabel.font = font;
            titleLabel.tag = 8003;
            titleLabel.userInteractionEnabled = NO;
            titleLabel.text = self.featureLink.title;
            [self addSubview:titleLabel];
        } else {
            titleLabel.frame = frame;
        }
        
        // subtitle
        frame.origin.y += frame.size.height + 0;
        
        font = [UIFont systemFontOfSize:13];
        size = [self.featureLink.subtitle sizeWithFont:font constrainedToSize:CGSizeMake(frame.size.width, 2000)];
        frame.size.height = size.height;
        
        UILabel *subtitleLabel = (UILabel *)[self viewWithTag:8004];
        if (!subtitleLabel) {
            subtitleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
            subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            subtitleLabel.backgroundColor = [UIColor clearColor];
            subtitleLabel.textColor = [UIColor whiteColor];
            subtitleLabel.font = font;
            subtitleLabel.lineBreakMode = UILineBreakModeWordWrap;
            subtitleLabel.numberOfLines = 2;
            subtitleLabel.tag = 8004;
            subtitleLabel.userInteractionEnabled = NO;
            subtitleLabel.text = self.featureLink.subtitle;
            [self addSubview:subtitleLabel];
        } else {
            subtitleLabel.frame = frame;
        }
        
        // disclosure
        CGRect labelBounds = [subtitleLabel textRectForBounds:subtitleLabel.bounds limitedToNumberOfLines:1];
        CGFloat originY;
        NSInteger position = [subtitleLabel.text lengthOfLineWithFont:font constrainedToSize:labelBounds.size];
        if (position < subtitleLabel.text.length) {
            NSString *substring = [subtitleLabel.text substringFromIndex:position];
            size = [substring sizeWithFont:font];
            originY = frame.origin.y + size.height;
        } else {
            size = [subtitleLabel.text sizeWithFont:font];
            originY = frame.origin.y;
        }
        CGRect triangleFrame = CGRectMake(subtitleLabel.frame.origin.x + size.width + 1, originY, 10, size.height);
        
        UILabel *triangleLabel = (UILabel *)[self viewWithTag:8005];
        if (!triangleLabel) {
            triangleLabel = [[[UILabel alloc] initWithFrame:triangleFrame] autorelease];
            triangleLabel.textColor = arrowColor;
            triangleLabel.font = [UIFont systemFontOfSize:10];
            triangleLabel.text = @"\u25b6";
            triangleLabel.backgroundColor = [UIColor clearColor];
            triangleLabel.tag = 8005;
            [self addSubview:triangleLabel];
        } else {
            triangleLabel.frame = triangleFrame;
        }
    }
}

- (void)wasTapped:(id)sender {
    NSURL *url = [NSURL URLWithString:self.featureLink.url];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)dealloc {
    self.featureLink = nil;
    [super dealloc];
}

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data {
    self.featureLink.photo = data;
    [CoreDataManager saveData];
    [self setNeedsLayout];
    [self.superview setNeedsLayout];
}

@end
