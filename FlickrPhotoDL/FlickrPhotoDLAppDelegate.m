//
//  FlickrPhotoDLAppDelegate.m
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



#import "FlickrPhotoDLAppDelegate.h"
#import <dispatch/dispatch.h>
#import "RAFrSetInfo.h"


@implementation FlickrPhotoDLAppDelegate

@synthesize window = _window;
@synthesize isOriginal;
@synthesize flickrSetURLTextField;
@synthesize addButton;
@synthesize tableView;
@synthesize removeButton;
@synthesize downloadButton;
@synthesize progress;
@synthesize label;


- (id)init
{
    self = [super init];
    if (self) {
        isOriginal = NO;
        isStartDownload = NO;
        list = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    // mkdir ~/Downloads/FlickrPhotos directory
    NSFileManager *fm;
    fm = [NSFileManager defaultManager];
    NSString *dirPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads/FlickrPhotos"];
    //NSLog(@"dir path= %@", dirPath);
    
    BOOL isDir;
    if (!([fm fileExistsAtPath:dirPath isDirectory:&isDir] && isDir))
    {
        //NSLog(@"FlickrPhotos directory doesn't exist!");
        // FlickrPhotos directory doesn't exist, mkdir FlickrPhotos directory.
        if (![fm createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil]) {
            NSLog(@"Couldn't create directory: %@", dirPath);
        }
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    if (flag) {
        return NO;
    }
    else {
        [_window makeKeyAndOrderFront:self];
        return YES;
    }
}

- (void)awakeFromNib
{
    [label setStringValue:@""];
    [progress setHidden:YES];
    [removeButton setEnabled:NO];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [list count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [list objectAtIndex:row];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [removeButton setEnabled:YES];
    //NSInteger row = [flickrURLsTableView selectedRow];
    //NSLog(@"selected row: %ld", row);
    /*
    if (row > -1)
    {
        NSString *str = [list objectAtIndex:row];
        [statusLabel setStringValue:str];
    }*/
}

- (IBAction)addItem:(id)sender
{
    [list addObject:[flickrSetURLTextField stringValue]];
    [flickrSetURLTextField setStringValue:@""];
    [tableView reloadData];
}

- (IBAction)removeItem:(id)sender
{
    NSInteger row = [tableView selectedRow];
    [list removeObjectAtIndex:row];
    [tableView reloadData];
    [tableView deselectAll:self];
    [removeButton setEnabled:NO];
}

- (IBAction)downloading:(id)sender
{
    isStartDownload = !isStartDownload;
    if (isStartDownload) 
    {
        if (![progress isIndeterminate]) {
            [progress setIndeterminate:YES];
        }
        
        [progress setHidden:NO];
        [addButton setEnabled:NO];
        [tableView deselectAll:self];
        [tableView setEnabled:NO];
        [removeButton setEnabled:NO];
        [downloadButton setTitle:@"Stop Download"];
        [progress startAnimation:self];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (NSString *frURLStr in list)
            {
                if (!isStartDownload) {
                    // isStartDownload == NO, stop downloading...
                    break;
                }
                RAFrSetInfo *frset = [[RAFrSetInfo alloc] initWithFlickrSetURL:frURLStr];
                
                if (frset) 
                {
                    // Update status label
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [label setStringValue:@"Get photo URLs..."];
                    });
                    
                    [frset imageURLsHandler:^(NSString *flickrName, NSString *flickrSetNum,
                                              NSMutableArray *imageURLs)
                     {
                         NSString *pathStr = [[NSString alloc] initWithFormat:@"Downloads/FlickrPhotos/%@/%@", flickrName, flickrSetNum];
                         NSString *dlPath = [NSHomeDirectory() stringByAppendingPathComponent:pathStr];
                         // mkdir
                         if (![self mkdirAtPath:dlPath]) {
                             NSLog(@"mkdir %@ fail!", dlPath);
                             return;
                         }
                         
                         NSInteger maxSteps = [imageURLs count];
                         NSString *statusStr1 = [[NSString alloc] initWithFormat:@"(0/%ld)  Downloading: %@, set-%@", maxSteps, flickrName, flickrSetNum];
                         
                         // Update progress indicator and label
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [progress setMinValue:0.0];
                             [progress setMaxValue:(double)maxSteps];
                             [label setStringValue:statusStr1];
                             
                             if ([progress isIndeterminate]) {
                                 [progress setDoubleValue:0.0];
                                 [progress stopAnimation:self];
                                 [progress setIndeterminate:NO];
                             }
                         });
                         
                         double steps = 1.0;
                         for (NSString *tempURL in imageURLs)
                         {
                             NSString *fileURL = [frset convertToFileURL:tempURL isOriginalSize:isOriginal];
                             if (!fileURL) {
                                 BOOL notIsOriginal = !isOriginal;
                                 fileURL = [frset convertToFileURL:tempURL isOriginalSize:notIsOriginal];
                             }
                             
                             if (!isStartDownload) {
                                 // isStartDownload == NO, stop downloading...
                                 return;
                             }
                             
                             NSString *statusStr2 = [[NSString alloc] initWithFormat:@"(%i/%ld)  Downloading: %@, set-%@", (int)steps ,maxSteps, flickrName, flickrSetNum];
                             
                             // download file
                             [self downloadFile:fileURL savePath:dlPath];
                             
                             // Update progress indicator and label
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [progress setDoubleValue:steps];
                                 [label setStringValue:statusStr2];
                             });
                             steps++;
                         }
                         
                         // Update progress indicator
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [progress setDoubleValue:0.0];
                         });
                     }]; // download handler blocks end.
                } // if frset end
            } // for in list end
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [progress setHidden:YES];
                if (![downloadButton isEnabled]) {
                    [downloadButton setEnabled:YES];
                }
                isStartDownload = NO;
                [downloadButton setTitle:@"Start Download"];
                [tableView setEnabled:YES];
                [addButton setEnabled:YES];
                [label setStringValue:@"Done! (Downloaded to the ~/Downloads/FlickrPhotos/)"];
            });
        }); // GCD blocks end
    }
    else {
        [downloadButton setTitle:@"Stoping..."];
        [downloadButton setEnabled:NO];
    }
}

- (BOOL)mkdirAtPath:(NSString *)path
{
    NSFileManager *fm;
    fm = [NSFileManager defaultManager];
    
    BOOL isDir;
    if (!([fm fileExistsAtPath:path isDirectory:&isDir] && isDir))
    {
        //NSLog(@"%@ directory doesn't exist!", path);
        // directory doesn't exist, so mkdir.
        if (![fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil]) {
            //NSLog(@"Couldn't create directory: %@", path);
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)downloadFile:(NSString *)aFileURL savePath:(NSString *)path
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/curl"];
    [task setCurrentDirectoryPath:path];
    
    NSArray *args = [NSArray arrayWithObjects:@"-O", aFileURL, nil];
    [task setArguments:args];
    
    [task launch];
    [task waitUntilExit];
        
    int taskStatus = [task terminationStatus];
    
    if (taskStatus != 0) {
        return NO;
    }
    
    return YES;
}


@end

