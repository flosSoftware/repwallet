//
//  NSFileManager+Utils.h
//  repWallet
//
//  Created by Alberto Fiore on 12/03/13.
//  Copyright 2013 Alberto Fiore. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Utils)

+ (NSString*) mimeTypeForFileAtPath: (NSString *) path;

+ (NSString*) mimeTypeForPathExtension: (NSString *) pathExtension;

@end
