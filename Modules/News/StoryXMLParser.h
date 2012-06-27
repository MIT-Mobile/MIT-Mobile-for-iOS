#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"

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

@interface StoryXMLParser : NSObject <ConnectionWrapperDelegate, NSXMLParserDelegate>

@property (nonatomic, assign) id <StoryXMLParserDelegate> delegate;
@property (nonatomic, retain) ConnectionWrapper *connection;
@property (nonatomic, retain) NSXMLParser *xmlParser;
@property (nonatomic, assign) BOOL parsingTopStories;
@property (nonatomic, assign) BOOL isSearch;
@property (nonatomic, assign) BOOL loadingMore;
@property (nonatomic, assign) NSInteger totalAvailableResults;
@property (nonatomic, retain) NSString *currentElement;
@property (nonatomic, retain) NSMutableArray *currentStack;
@property (nonatomic, retain) NSMutableDictionary *currentContents;
@property (nonatomic, retain) NSMutableDictionary *currentImage;
@property (nonatomic, retain) NSMutableArray *addedStories;

// called by main thread
- (void)loadStoriesForCategory:(NSInteger)category afterStoryId:(NSInteger)storyId count:(NSInteger)count;
- (void)loadStoriesforQuery:(NSString *)query afterIndex:(NSInteger)start count:(NSInteger)count;
- (void)abort;

@end
