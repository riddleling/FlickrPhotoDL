//
//  FlickrPhotoDLAppDelegate.h
//
//
//  Copyright (c) 2012 Wei-Chen Ling.
// 
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//
//




#import <Cocoa/Cocoa.h>

@interface FlickrPhotoDLAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
    NSMutableArray *list;
    BOOL isOriginal;
    BOOL isStartDownload;
}
@property BOOL isOriginal;
@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *flickrSetURLTextField;
@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSButton *removeButton;
@property (weak) IBOutlet NSButton *downloadButton;
@property (weak) IBOutlet NSProgressIndicator *progress;
@property (weak) IBOutlet NSTextField *label;


- (IBAction)addItem:(id)sender;
- (IBAction)removeItem:(id)sender;
- (IBAction)downloading:(id)sender;
- (BOOL)downloadFile:(NSString *)aFileURL savePath:(NSString *)path;
- (BOOL)mkdirAtPath:(NSString *)path;


@end
