#News

##Screens

###Top List

News root view. Top three stories from each category.

<a href="top_list_01.png"><img class="screen" src="top_list_01.png" width="160"></a> <a href="top_list_02.png"><img class="screen" src="top_list_02.png" width="160"></a>

Orientations: Portrait only

Storyboard ID = StoryListViewController

__Navbar__

Title = MIT News

Search button on right. See [Search](#search).

__Toolbar__

Centered status label. See [Toolbar](#toolbar).

__Content__

_pull-to-refresh Tableview_

+ Sections

    - One for each category in [http://m.mit.edu/apis/news/categories](http://m.mit.edu/apis/news/categories) (i.e. Latest MIT News, In the Media, and Around Campus).

    - Tap section header to browse all stories in that category (leads to [Category List](#categorylist)).

    - Use `CategoryCell` in storyboard for section header view. Uses a UIToolbar to get the translucent iOS 7 effect. Doesn't seem to be any other way to get that effect yet. Will need to have a different cell/view for iOS 6.

    - Will need special coding (gesture recognizer) to make section headers tappable. The Photos app does it, so it's possible. Might be doable just via the Storyboard.

+ Rows

    - Top List screen shows top 3 stories in each category.
    
    - 3 kinds of cells:

        - `StoryCell` for stories with a dek.

        - `StoryNoDekCell` for stories with no dek (unless there's a way to make an empty dek collapse completely and not make the cell taller than it needs to be).

        - `StoryExternalCell` for stories from the In the Media category. They will have no body attribute, but it might be safer to check the category instead.

    - The UIImageViews used in those cells should be filled via SDWebImage.

Search button leads to [Search](#search) mode.

Tapping a `StoryCell` or `StoryNoDekCell` row pushes in [Story Detail](#storydetail) screen. Catch `showStory` segue for this.

Tapping a `StoryExternalCell` row pushes in [External Detail](#externaldetail) screen. Catch `showExternal` segue for this.

###Category List

Same as Top List, but with only one header-less section and an extra row at the bottom (`LoadMoreCell` from Storyboard table) to load more stories.

<a href="category_list_01.png"><img class="screen" src="category_list_01.png" width="160"></a> <a href="category_list_02.png"><img class="screen" src="category_list_02.png" width="160"></a> <a href="category_list_03.png"><img class="screen" src="category_list_03.png" width="160"></a>

Orientations: Portrait only

Storyboard ID = StoryListViewController

Navigation bar title is the name of the category. Back button is nameless.

Stories are loaded 20 at a time. More can be loaded from the "Load more..." row at the bottom of the table. Pull-to-refresh to reload the first 20.

When tapped, Load More… turns disabled until loading completes or fails. Also, [toolbar](#toolbar) status message shows "Updating…" while updating.

Search button leads to [Search](#search) mode.

Category List uses URLs like [http://m.mit.edu/apis/news/stories?category=1&limit=20](http://m.mit.edu/apis/news/stories?category=1&limit=20).

###Search

Modal state of [Top List](#toplist) and [Category List](#categorylist) screens.

<a href="search_01.png"><img class="screen" src="search_01.png" width="160"></a> <a href="search_02.png"><img class="screen" src="search_02.png" width="160"></a> <a href="search_03.png"><img class="screen" src="search_03.png" width="160"></a>

Not in storyboard. Needs to added in code.

A search in Top List searches all categories at once and returns all results mixed into a single section. A search from Category List searches all categories at once and returns all results mixed into a single section.

Results are loaded 20 at a time. More can be loaded from the "Load more..." row at the bottom of the table, just as in Category List.

Search uses URLs like [http://m.mit.edu/apis/news/stories?q=banana&limit=20](http://m.mit.edu/apis/news/stories?q=banana&limit=20).

###Story Detail

<a href="detail_01.png"><img class="screen" src="detail_01.png" width="160"></a> 

Orientations: Portrait only

Storyboard ID = DetailViewController

Title = blank

Share button on right of navigation bar. Shares link to story. Includes title and dek as appropriate.

No favoriting stories.

No toolbar.

Content is a web view template. Story's primary image, if available, is placed at top. Image can be tapped to go to [Image Gallery](#imagegallery). If story has images but no primary image, the gallery can be reached via an image-less link to the gallery below the story title/dek/byline area.

Updated web template forthcoming.

###External Detail

Inline browser for links to external stories.

Orientations: Portrait only

Storyboard ID = DetailViewController

Uses same Storyboard scene as [Story Detail](#storydetail), but entered via a different segue (`showExternal` instead of `showStory`).

Image forthcoming.

Title = "Loading...", then &lt;title&gt; of loaded web page.

Share button at top right which first brings up a UIActionSheet with the choices "Open in Safari", "Share Link", and "Cancel".

Toolbar with back and forward buttons. Artwork for those forthcoming.

###Image Gallery

Modal presentation. Slides up from bottom over Story Detail. Scroll view with caption in a view in a UIPageViewController in a UINavigationController.

> Look at Apple's [Photo Scroller](https://developer.apple.com/library/ios/samplecode/PhotoScroller/) sample UIPageViewController/UIScrollView app for how to accomplish this. Or see if there's a library on GitHub with an acceptable license that does this.

<a href="gallery_01.png"><img class="screen" src="gallery_01.png" width="160"></a> <a href="gallery_02.png"><img class="screen" src="gallery_02.png" width="160"></a> <a href="gallery_03.png"><img class="screen" src="gallery_03.png" width="160"></a> 

Orientations: All but upside-down.

Storyboard ID = GalleryNavigationController

Navigation bar title = "x of y". Done button and Action button.

No toolbar.

__Content__

- Pinch and zoom image
- Overlayed caption and credit at bottom
- Only partially implemented in initial storyboard. Only part that works is the sizing of the caption and tapping to hide/show the UI.

__Behavior__

- pinch, zoom, pan image
- swipe to next/previous image (no wrapping around the end)
- navbar title gives context and count, e.g. "2 of 4"
- tap image once to toggle visibility of navbar and caption
- tap action button to share current image (with its caption if possible and appropriate)
- tap done button to dismiss modal and return to story

##Shared Elements and Special Behaviors

###Caching, Loading, and Refreshing

Only the [Top List](#toplist) and [Category List](#categorylist) screens cache stories and refresh their contents on viewWillAppear. Searches aren't cached and the Story Detail screen just takes what its parent gives it.

The two API resources to be cached are the category list call ([http://m.mit.edu/apis/news/categories](http://m.mit.edu/apis/news/categories)) and the list of stories in those categories ([http://m.mit.edu/apis/news/stories?categories=1](http://m.mit.edu/apis/news/stories?categories=1)).

Both of those include cache-control headers which should be relied upon to decide how long to cache that data. Top List and Category List should check on viewWillAppear if their relevant cached data is stale and refresh it as needed.

Story images should be loaded lazily.

There is some code in the app from the Dining module which clears out the SDWebImage cache after a set amount of time. That code may need to be modified to play well with News.

###Toolbar

Appears on Top List and Category List screens, but not on Story Detail screen. Behavior and appearance is similar to the status bar in Mail app.

__Status messages__

```
 busy          Updating...

 < 1 minute    Updated Just Now

 < 2 minutes   Updated 1 minute ago

 < 6 minutes   Updated x minutes ago

>= 6 minutes   Updated at 11:00 AM

 another day   Updated on 1/6/2013
```

Wasn't able to add statusLabel UILabel in Storyboard. Here's a code snippet for adding the status message label to a UIViewController:

```
// Toolbar comes automatically as part of the navigation controller.

self.statusLabel = [[UILabel alloc] init];
self.statusLabel.font = [UIFont systemFontOfSize:12.];

[self setToolbarItems:@[
                        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                      target:nil
                                                                      action:NULL],
                        [[UIBarButtonItem alloc] initWithCustomView:statusLabel],
                        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                      target:nil
                                                                      action:NULL]
                        ]
             animated:NO
 ];

statusLabel.text = @"Updating...";
[statusLabel sizeToFit];
```

###Photos app-style Showing and Hiding of UI

```
- (IBAction)toggleUI:(id)sender {
    self.hidesUI = !self.hidesUI;
    
    CGRect barFrame = self.navigationController.navigationBar.frame;

    CGFloat alpha = (self.hidesUI) ? 0.0 : 1.0;
    [UIView animateWithDuration:0.33 animations:^{
        if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
            [self setNeedsStatusBarAppearanceUpdate];
        } else {
            [[UIApplication sharedApplication] setStatusBarHidden:self.hidesUI];
        }
        self.navigationController.navigationBar.alpha = alpha;
        self.captionView.alpha = alpha;
    }];
    
    self.navigationController.navigationBar.frame = CGRectZero;
    self.navigationController.navigationBar.frame = barFrame;
}

- (BOOL)prefersStatusBarHidden {
    return self.hidesUI;
}
```
