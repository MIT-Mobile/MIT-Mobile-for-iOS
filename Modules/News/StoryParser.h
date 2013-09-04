#import <Foundation/Foundation.h>
#import "NewsStory.h"
#import "CoreDataManager.h"

@class StoryParser;

@protocol StoryParserDelegate <NSObject>
@required
- (void)didFinishParsing:(StoryParser *)storyParser;
- (void)parserStories:(StoryParser *)storyParser didFailDownload:(NSError *)error;
- (void)parserStories:(StoryParser *)parser didMakeProgress:(CGFloat)percentDone;
@end

@interface StoryParser : NSObject

@property (nonatomic,assign) id <StoryParserDelegate> delegate;

- (void)loadStoriesForCategory:(NSInteger)category afterStoryId:(NSInteger)storyId count:(NSInteger)count;
- (void)downloadAndParseURL:(NSURL *)url;
- (void) updateInfo:(NSDictionary *)storyInfo;
- (NSString *)newsTagThumbURL;
- (NewsImage *)imageWithDictionary:(NSDictionary *)imageDict;
- (NewsImageRep *)imageRepForURLString:(NSString *)urlString;
- (void)addGalleryImage:(NewsImage *)newImage;
- (void)loadStoriesforQuery:(NSString *)query afterIndex:(NSInteger)start count:(NSInteger)count;
- (void)reportProgress:(NSNumber *)percentComplete;

@property BOOL parseTopStories;
@property BOOL isSearch;
@property (nonatomic, assign) BOOL loadingMore;
@property (nonatomic, assign) NSMutableArray *addedStories;

@end
