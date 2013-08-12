#import <Foundation/Foundation.h>


@class StoryXMLParser;
@class NewsImage;
@class NewsImageRep;

@protocol StoryXMLParserDelegate <NSObject>

- (void)parserDidFinishParsing:(StoryXMLParser *)parser;

@optional
- (void)parserDidStartDownloading:(StoryXMLParser *)parser;
- (void)parserDidStartParsing:(StoryXMLParser *)parser;
- (void)parser:(StoryXMLParser *)parser didMakeProgress:(CGFloat)percentDone;
- (void)parser:(StoryXMLParser *)parser didFailWithDownloadError:(NSError *)error;
- (void)parser:(StoryXMLParser *)parser didFailWithParseError:(NSError *)error;
@end

@interface StoryXMLParser : NSObject <NSXMLParserDelegate>
@property (nonatomic, weak) id <StoryXMLParserDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *addedStories;
@property (nonatomic) NSInteger totalAvailableResults;
@property (getter = isParsingTopStories) BOOL parsingTopStories;
@property (nonatomic,getter = isSearch) BOOL search;
@property (nonatomic) BOOL loadingMore;

// called by main thread
- (void)loadStoriesForCategory:(NSInteger)category afterStoryId:(NSInteger)storyId count:(NSInteger)count;
- (void)loadStoriesforQuery:(NSString *)query afterIndex:(NSInteger)start count:(NSInteger)count;
- (void)abort;

@end
