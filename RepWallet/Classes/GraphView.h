//
//  GraphView.h
//  repWallet
//
//  Created by Alberto Fiore on 3/12/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"

@interface GraphView : UIViewController<CPTPlotDataSource, CPTAxisDelegate> {
    CPTXYGraph *graph;
    NSMutableArray *dataForPlot;
    NSMutableArray *pointArray;
    NSMutableArray *labelsArray;
    NSMutableArray *labelsTickLocationsArray;
    NSNumber * yMin;
    NSNumber * yMax;
    int lastSelectedIndex;
    CPTPlotSpaceAnnotation *symbolTextAnnotation;
}

@property (nonatomic, retain) CPTXYGraph *graph;
@property (nonatomic,retain) NSMutableArray *dataForPlot;
@property (nonatomic,retain) NSMutableArray *pointArray;
@property (nonatomic,retain) NSMutableArray *labelsArray;
@property (nonatomic,retain) NSMutableArray *labelsTickLocationsArray;
@property (nonatomic,retain) NSNumber * yMin;
@property (nonatomic,retain) NSNumber * yMax;

-(id)initWithLabelsAndValues:(NSMutableArray *)data;
-(void)addPlotForPoints:(NSMutableArray *)points andGraphHasToBeCleared:(BOOL)hasToBeCleared;

@end
