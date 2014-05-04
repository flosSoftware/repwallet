//
//  NSString+HTML.m
//  repWallet
//
//  Created by Alberto Fiore on 6/22/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "NSString+HTML.h"


@implementation NSString (NSString_HTML)

- (void) removeHtmlTag:(NSString *)tagName addTrailingString:(NSString *)trailingString 
{
    NSError *error = NULL;
    
    NSString *regEx = [NSString stringWithFormat:@"<(?:%@)(?:[^>]*?)>(.*?)<\/(?:%@)>", tagName, tagName];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regEx options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
    if (!match) {
        
        NSLog(@"No matches found for open and closed HTML tag %@", tagName);
    }
    
    NSString *tmpl = nil;
    
    if (trailingString)
        tmpl = [NSString stringWithFormat:@"%@$1", trailingString];
    else
        tmpl = @"$1";
    
    NSString *selfNoOpenClosedTags = [regex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, [self length]) withTemplate:tmpl];
    
    // remove also single tags
    regEx = [NSString stringWithFormat:@"<(?:%@)(?:[^>]*?)\/>", tagName];
    regex = [NSRegularExpression regularExpressionWithPattern:regEx options:NSRegularExpressionCaseInsensitive error:&error];
    
    match = [regex firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
    if (!match) {
        
        NSLog(@"No matches found for single HTML tag %@", tagName);
    }
    
    if (trailingString)
        tmpl = [NSString stringWithFormat:@"%@", trailingString];
    else
        tmpl = @"";
    
    self = [regex stringByReplacingMatchesInString:selfNoOpenClosedTags options:0 range:NSMakeRange(0, [selfNoOpenClosedTags length]) withTemplate:tmpl];

}

- (void) removeGenericHtmlTagAndAddTrailingString:(NSString *)trailingString 
{
    NSError *error = NULL;
    
    NSString *regEx = @"<[A-Z]+(?:[^>]*?)>(.*?)<\/[A-Z]+>";
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regEx options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
    if (!match) {
        
        NSLog(@"No matches found for open and closed HTML tags");
    }
    
    NSString *tmpl = nil;
    
    if (trailingString)
        tmpl = [NSString stringWithFormat:@"%@$1", trailingString];
    else
        tmpl = @"$1";
    
    NSString *selfNoOpenClosedTags = [regex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, [self length]) withTemplate:tmpl];
    
    // remove also single tags
    regEx = @"<[A-Z]+(?:[^>]*?)\/>";
    regex = [NSRegularExpression regularExpressionWithPattern:regEx options:NSRegularExpressionCaseInsensitive error:&error];
    
    match = [regex firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
    if (!match) {
        
        NSLog(@"No matches found for single HTML tags");
    }
    
    if (trailingString)
        tmpl = [NSString stringWithFormat:@"%@", trailingString];
    else
        tmpl = @"";
    
    self = [regex stringByReplacingMatchesInString:selfNoOpenClosedTags options:0 range:NSMakeRange(0, [selfNoOpenClosedTags length]) withTemplate:tmpl];
}

@end
