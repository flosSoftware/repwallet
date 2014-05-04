#import <Foundation/Foundation.h>
#import "UITableDataSourceController.h"

@interface DocFileBrowserItem : UITableDataSourceController{
	BOOL isDirectory;
	NSString *fileTitle;
	NSString *path;
	BOOL isSelectable;
}

@property (nonatomic, assign) BOOL isDirectory;
@property (nonatomic, retain) NSString *fileTitle;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, assign) BOOL isSelectable;

+ (DocFileBrowserItem*)itemWithTitle:(NSString *)t andPath:(NSString *)p isDirectory:(BOOL)isDir;

@end
