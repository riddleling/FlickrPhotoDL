//
//  RAFrSetInfo.m
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




#import "RAFrSetInfo.h"

@interface RAFrSetInfo (RAPrivateMethods)

- (NSString *)_htmlContent:(NSString *) urlString;
- (NSArray *)_imageURLsOfPage:(NSString *)htmlString;
- (int)_pages:(NSString*) htmlString;

@end


@implementation RAFrSetInfo

#pragma mark -
#pragma mark Initializers

// init and setup flickrSetURL, flickrName, flickrSetNumber.
- (id)initWithFlickrSetURL:(NSString *) aString
{
    self = [super init];
    if (self != nil)
    {
        NSRegularExpression *expression = [NSRegularExpression 
                                           regularExpressionWithPattern:@"http://www\\.flickr\\.com/photos/(.+)/sets/(\\d+)/" 
                                           options:NSRegularExpressionCaseInsensitive 
                                           error:nil];
        
        NSTextCheckingResult *matchStr = [expression firstMatchInString:aString options:0 range:NSMakeRange(0, [aString length])];
        
        if (matchStr) {
            NSRange range1 = [matchStr rangeAtIndex:1];
            NSString *frNameStr = [aString substringWithRange:range1];
            
            NSRange range2 = [matchStr rangeAtIndex:2];
            NSString *frSetNumberStr = [aString substringWithRange:range2];
            
            flickrName_ = frNameStr;
            flickrSetNumber_ = frSetNumberStr;
            flickrSetURL_ = aString;
        }
        else {
            // init failed!
            return nil;
        }
        
    }
    return self;
}


#pragma mark -
#pragma mark Public Methods

// flickrSetURL getter.
- (NSString *)flickrSetURL
{
    return flickrSetURL_;
}


// Print flickrSetURL, flickrName, flickrSetNumber.
- (void)printFlickrSetBaseInfo
{
    NSLog(@"Flickr Set Info:");
    NSLog(@"=> URL: %@", flickrSetURL_);
    NSLog(@"=> ID: %@", flickrName_);
    NSLog(@"=> SetNumber: %@", flickrSetNumber_);
    
}


// Get all image URLs.
- (void)imageURLsHandler:(void (^) (NSString*, NSString*, NSMutableArray*)) handler
{
    NSString *htmlText = [self _htmlContent:flickrSetURL_];
    
    int pagesNumber;
    
    NSMutableArray *imageURLArray = [[NSMutableArray alloc] init];
    
    if (htmlText)
    {
        pagesNumber = [self _pages:htmlText];
        //NSLog(@"PagesNumber: %i", pagesNumber);
                
        // get image URL list of a page
        NSArray *urlList = [self _imageURLsOfPage:htmlText];
        [imageURLArray addObjectsFromArray:urlList];
    }
    
    int i;
    for (i=2; i<=pagesNumber; i++)
    {
        NSString *pageURL = [NSString stringWithFormat:@"%@?page=%i", flickrSetURL_, i];
        
        NSString *htmlText2 = [self _htmlContent:pageURL];
        if (htmlText2)
        {
            NSArray *urlList2 = [self _imageURLsOfPage:htmlText2];
            [imageURLArray addObjectsFromArray:urlList2];            
        }

    }
    
    // Run Block.
    handler(flickrName_, flickrSetNumber_, imageURLArray);
    
}


// Convert image URL to file URL.
- (NSString *)convertToFileURL:(NSString *)imageURL isOriginalSize:(BOOL)flag
{
    NSString *regexpStr = [[NSString alloc] initWithString:@"(http://www\\.flickr\\.com/photos/.+/\\d+/)(in/set-\\d+)"];
    
    NSMutableString *outputString = [[NSMutableString alloc] init];
                                       
    NSRegularExpression *urlExpression = [NSRegularExpression 
                                       regularExpressionWithPattern:regexpStr
                                       options:NSRegularExpressionCaseInsensitive 
                                       error:nil];
    
    NSTextCheckingResult *urlMatchStr = [urlExpression firstMatchInString:imageURL options:0 range:NSMakeRange(0, [imageURL length])];
    
    if (urlMatchStr)
    {
        NSRange range1 = [urlMatchStr rangeAtIndex:1];
        NSString *str1 = [imageURL substringWithRange:range1];
        
        NSRange range2 = [urlMatchStr rangeAtIndex:2];
        NSString *str2 = [imageURL substringWithRange:range2];
    
        if (flag) {
            [outputString appendFormat:@"%@sizes/o/%@/", str1, str2];
        }
        else {
            [outputString appendFormat:@"%@sizes/l/%@/", str1, str2];
        }
    }
    //NSLog(@"%@", outputString);
    
    
    NSString *htmlText = [self _htmlContent:outputString];
    //NSLog(@"%@", htmlText);
    
    NSString *fileRegexpStr;
    
    if (flag) {
        fileRegexpStr = [[NSString alloc] initWithString:@"<img src=\"(.+?_o\\.jpg)\">"];
    }
    else {
        fileRegexpStr = [[NSString alloc] initWithString:@"<img src=\"(.+?_b\\.jpg)\">"];
    }
    
    NSRegularExpression *fileExpression = [NSRegularExpression 
                                       regularExpressionWithPattern:fileRegexpStr 
                                       options:NSRegularExpressionCaseInsensitive 
                                       error:nil];
    
    NSTextCheckingResult *fileMatchStr = [fileExpression firstMatchInString:htmlText options:0 range:NSMakeRange(0, [htmlText length])];
    
    if (fileMatchStr)
    {
        NSRange range = [fileMatchStr rangeAtIndex:1];
        NSString *fileURL = [htmlText substringWithRange:range];
        return fileURL;
    }
    return nil;
}


#pragma mark -
#pragma mark Private Methods

// Get HTML.
- (NSString *)_htmlContent:(NSString *) urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestReloadIgnoringCacheData
                                            timeoutInterval:30];
    NSURLResponse *urlResponse;
    NSError *error;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:urlRequest
                                                 returningResponse:&urlResponse
                                                             error:&error];
    if(responseData)
    {
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        //NSLog(@"%@", responseString);
        return responseString;
    }
    return nil;
}


// Get image URLs of a page.
- (NSArray *)_imageURLsOfPage:(NSString *) htmlString
{
    NSMutableString *regexpStr = [[NSMutableString alloc] init];    
    [regexpStr appendFormat:@"\"photo-click\" href=\"(/photos/%@/\\d+/in/set-%@)\".+?_s\\.jpg", flickrName_, flickrSetNumber_];
    //NSLog(@"regExp: %@", regexpStr);
    
    
    NSMutableString *outputString = [[NSMutableString alloc] init];
    
    NSRegularExpression *expression = [NSRegularExpression 
                                       regularExpressionWithPattern:regexpStr
                                       options:NSRegularExpressionCaseInsensitive 
                                       error:nil];
    NSArray *array = [expression matchesInString:htmlString options:0 range:NSMakeRange(0, [htmlString length])];
    
    
    for (NSTextCheckingResult *matchStr in array)
    {
        NSRange range1 = [matchStr rangeAtIndex:1];
        NSString *str1 = [htmlString substringWithRange:range1];

        [outputString appendFormat:@"http://www.flickr.com%@\n", str1];
    }
    //NSLog(@"%@", outputString);
    
    NSArray *tempArray = [outputString componentsSeparatedByString:@"\n"];
    NSRange arrayRange = NSMakeRange(0, [tempArray count]-1);
    
    NSArray *urlsArray = [tempArray subarrayWithRange:arrayRange];
    
    if (urlsArray)
    {
        return urlsArray;
    }

    return nil;
}


// Get Pages Number.
- (int)_pages:(NSString *) htmlString
{
    NSMutableString *outputString = [[NSMutableString alloc] init];
    
    NSRegularExpression *expression = [NSRegularExpression 
                                       regularExpressionWithPattern:@"\\?page=(\\d+)" 
                                                            options:NSRegularExpressionCaseInsensitive 
                                                              error:nil];
    NSArray *array = [expression matchesInString:htmlString options:0 range:NSMakeRange(0, [htmlString length])];
    
    int maxNumber = 1;
    
    for (NSTextCheckingResult *matchStr in array)
    {
        NSRange range = [matchStr rangeAtIndex:1];
        NSString *pagesNumber = [htmlString substringWithRange:range];
        [outputString appendFormat:@"%@ ", pagesNumber];
       
        int tempNumber = [pagesNumber intValue];
        
        if (tempNumber > maxNumber)
        {
            maxNumber = tempNumber;
        }
        
    }
    //NSLog(@"%@", outputString);
    //NSLog(@"max pages number: %i", maxNumber);
    return maxNumber;
}


@end
