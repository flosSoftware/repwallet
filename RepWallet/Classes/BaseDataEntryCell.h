//
//  BaseDataEntryCell.h
//  repWallet
//
//  Created by Alberto Fiore on 3/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RepWalletAppDelegate.h"

#define RIGHT_PADDING 10
#define IPAD_RIGHT_PADDING 20
#define UNDERLINE_PADDING 10
#define IPAD_UNDERLINE_PADDING 30
#define SEPARATOR_ROW_HEIGHT 1.5
#define IPAD_SEPARATOR_ROW_HEIGHT 2
#define BTN_BOTTOM_PADDING 2
#define IPAD_BTN_BOTTOM_PADDING 4

// Nome della notifica di fine editing
#define CELL_ENDEDIT_NOTIFICATION_NAME @"cellEndEdit"
// Nome della notifica di ERRATO editing
#define CELL_WRONGEDIT_NOTIFICATION_NAME @"cellWrongEdit"

@interface BaseDataEntryCell : UITableViewCell {
	// determina il diverso comportamento di layoutsubviews...
    BOOL _isAddEditCell;
}

@property (nonatomic, retain) NSString *boundClassName;

@property (nonatomic, retain) NSString *dataKey;

@property (nonatomic, assign) BOOL mandatory;

@property (nonatomic, assign) BOOL enabledCell;

@property (nonatomic, retain) NSString *disablingDK;

@property (nonatomic, retain) NSString *disablingValue;

@property (nonatomic, assign, getter=hasValidControlValue) BOOL validControlValue;

@property (nonatomic, retain) UIColor *color;

// Imposta il valore del controllo gestito (TextField, ...)
- (void) setControlValue:(id)value;

// Legge il valore dal controllo
- (id) getControlValue;

// Helper per l'invio della notifica di fine editing
- (void) postEndEditingNotification;

// Helper per l'invio della notifica di errato editing
- (void) postWrongEditingNotification;

// Change cell style for wrong typing notification
- (void) setRedAlert;

- (void) removeRedAlert;

- (void) setEnabled:(BOOL)enabled;

// Connect this cell to disabling notifications from another cell
- (void) setDisablingDK:(NSString *)disablingDK forValue:(NSString *)disablingValue;

// Metodo che verrà chiamato da setEnabled
- (void) changeMandatoryStatusTo:(BOOL)mandatory;

- (BOOL) isMandatory;

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label color:(UIColor *)color;

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label;

// Get the viewController for the cell
- (UIViewController*)viewController;

- (void)setIsAddEditCell:(BOOL)isAddEditCell;

@end