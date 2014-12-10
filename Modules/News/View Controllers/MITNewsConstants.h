#import <Foundation/Foundation.h>

extern NSString* const MITNewsLoadMoreCellIdentifier;
extern NSString* const MITNewsLoadMoreCellNibName;
extern CGFloat const MITNewsLoadMoreTableViewCellHeight;

// Regular stories consist of an optional image,
// an optional dek, and a title
#pragma mark Regular stories
extern NSString* const MITNewsStoryCellIdentifier;
extern NSString* const MITNewsStoryCellNibName;
extern NSString* const MITNewsStoryNoDekCellIdentifier;
extern NSString* const MITNewsStoryNoDekCellNibName;

// 'External' stories are stories that just consist of an optional
// branding image (NPR, New York Times, etc), a dek, and a link
#pragma mark External stories
extern NSString* const MITNewsStoryExternalType;
extern NSString* const MITNewsStoryExternalCellIdentifier;
extern NSString* const MITNewsStoryExternalCellNibName;
extern NSString* const MITNewsStoryExternalNoImageCellIdentifier;
extern NSString* const MITNewsStoryExternalNoImageCellNibName;

extern NSString* const MITNewsCategoryHeaderIdentifier;
extern NSUInteger const MITNewsDefaultNumberOfStoriesPerPage;
extern CGFloat const MITNewsRefreshControlHangTime;

#pragma mark iPad stories

extern NSString* const MITNewsCellIdentifierStoryJumbo;
extern NSString* const MITNewsCellIdentifierStoryDek;
extern NSString* const MITNewsCellIdentifierStoryClip;
extern NSString* const MITNewsCellIdentifierStoryWithImage;
extern NSString* const MITNewsCellIdentifierStoryLoadMore;
extern NSString* const MITNewsReusableViewIdentifierSectionHeader;
extern NSString* const MITNewsReusableViewIdentifierDivider;
