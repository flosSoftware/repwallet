//
//  NSString+HTML.h
//  repWallet
//
//  Created by Alberto Fiore on 6/22/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (NSString_HTML)

- (void) removeHtmlTag:(NSString *)tagName addTrailingString:(NSString *)trailingString;
- (void) removeGenericHtmlTagAndAddTrailingString:(NSString *)trailingString;
@end

